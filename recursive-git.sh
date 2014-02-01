#! /bin/bash

function column_err {
  printf "\033[41m%-10s\033[0m" "$1"
}
function column_ok {
  printf "\033[32m%-10s\033[0m" "$1"
}
function column_neutral {
  printf "\033[33m%-10s\033[0m" "$1"
}
function column_heading {
  printf "\e[48;5;237m%-${HEADER_SIZE}s\e[0m" "$1"
}
function column_sub_heading {
  printf "\e[48;5;243m%-${HEADER_SIZE}s\e[0m" "$1"
}


function proj_name() {
  column_heading $(pwd | sed 's,^.*/,,')
}

function get_curr_branch() {
  GIT_CURRENT_BRANCH=`git branch | sed -n '/^*/s/^* //p'`
}

function curr_branch() {
  get_curr_branch;
  if [ "$GIT_CURRENT_BRANCH" == "master" ]
  then
    column_ok $GIT_CURRENT_BRANCH
  else
    column_neutral $GIT_CURRENT_BRANCH
  fi
}

function dirty_state() {
  if ( ! git diff --no-ext-diff --quiet --exit-code ) ||
    git ls-files --others --exclude-standard --error-unmatch -- '*' &> /dev/null 
  then
    column_err "dirty"
  else
    column_ok "clean"
  fi
}

function ahead_of_upstream() {
  count=$(git rev-list --count "@{upstream}"..HEAD 2>/dev/null) || return 100
  (( $count != "0"))
}

function behind_upstream() {
  count=$(git rev-list --count HEAD.."@{upstream}" 2>/dev/null) || return 100
  (( $count != "0"))
}

function not_on_upstream() {
  count=$(git rev-list --count HEAD..."@{upstream}" 2>/dev/null) || return 0
  (( $count != "0"))
}

function local_state() {
  ahead_of_upstream && column_err "To push" || column_ok "push ok"
}
  
function remote_state() {
  behind_upstream && column_err "To pull" || column_ok "pull ok"
}

function short_git_log() {
  label=$1
  revspec=$2

  column_sub_heading "   ${label}"
  echo 

  git log --pretty=format:"   %h  %C(yellow)%<(14,trunc)%an%Creset  %s %C(dim cyan)(%ar)%Creset" --date=short --color=always ${revspec}
  echo; echo
}

function log_only_upstream() {
  short_git_log "Only on upstream:" 'HEAD..@{upstream}'
}

function log_only_local() {
  short_git_log "Only local:"  '@{upstream}..HEAD'
}

function git_fetch() {
  if [[ -z "$NOFETCH" ]]; then
    git fetch &> /dev/null
  fi
}

function project_status() {
  curr_branch
  git_fetch
  dirty_state; local_state; remote_state;
  echo
  if [[ -n "${VERBOSE}" ]]; then
    behind_upstream && log_only_upstream
    ahead_of_upstream && log_only_local
  fi
  if [[ -n "${VERY_VERBOSE}" ]]; then
    if not_on_upstream; then
      column_sub_heading '   Diff HEAD upstream'; echo
      git diff -b HEAD "@{upstream}" --color=always | sed 's/^/'"   "'/'
      echo
    fi
  fi
}

function do_command() {
  #proj_name
  #echo
  #echo $*
  eval $*
  echo
}

function define_header_size() {
  local size=$(find . -type d -name .git -exec sh -c "echo {} | sed -e s,/.git,, -e s,^./,, | wc -c" \; | sort -n | tail -1)

  export HEADER_SIZE=${size:=10}
}

function rgit_foreach() {
  for dir in $(find . -type d -name '.git'); do
    pushd $dir/.. &> /dev/null ; eval "$*" ; popd &> /dev/null
  done
}

function rgit_status() {
  define_header_size
  rgit_foreach "proj_name; project_status"
}


function rgit_dosh() {
  define_header_size
  rgit_foreach "proj_name; echo; echo $*; $*; echo"
}

function rgit_pull() {
  rgit_dosh git pull --ff-only
}

function rgit() {
  if [[ "$2" == "-v" || "$1" == "-v" ]]; then
    VERBOSE=true
  fi
  if [[ "$2" == "-vv" || "$1" == "-vv" ]]; then
    VERBOSE=true
    VERY_VERBOSE=true
  fi

  case $1 in
  "pull")
    rgit_pull
    ;;
  "show")
    rgit_status
    ;;
  "dosh")
    rgit_dosh "${*:2}"
    ;;
  "do")
    rgit_dosh git ${*:2}
    ;;
  *)
    rgit_status
    ;;
  esac

  unset VERBOSE
  unset VERY_VERBOSE
}
