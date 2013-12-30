#! /bin/bash

function column-err {
  printf "\033[41m%-10s\033[0m" "$1"
}
function column-ok {
  printf "\033[32m%-10s\033[0m" "$1"
}
function column-neutral {
  printf "\033[33m%-10s\033[0m" "$1"
}
function column-heading {
  printf "\e[48;5;237m%-${HEADER_SIZE}s\e[0m" "$1"
}


function proj_name() {
  column-heading $(pwd | sed 's,^.*/,,')
}

function get_curr_branch() {
  GIT_CURRENT_BRANCH=`git branch | sed -n '/^*/s/^* //p'`
}

function curr_branch() {
  get_curr_branch;
  if [ "$GIT_CURRENT_BRANCH" == "master" ]
  then
    column-ok $GIT_CURRENT_BRANCH
  else
    column-neutral $GIT_CURRENT_BRANCH
  fi
}

function dirty_state() {
  if ( ! git diff --no-ext-diff --quiet --exit-code ) ||
    git ls-files --others --exclude-standard --error-unmatch -- '*' &> /dev/null 
  then
    column-err "dirty"
  else
    column-ok "clean"
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

function local_state() {
  ahead_of_upstream && column-err "To push" || column-ok "push ok"
}
  
function remote_state() {
  behind_upstream && column-err "To pull" || column-ok "pull ok"
}

function project_status() {
  pushd $1/.. > /dev/null
  proj_name;
  curr_branch
  git fetch &> /dev/null
  dirty_state; local_state; remote_state;
  echo
  popd > /dev/null
}

export -f ahead_of_upstream
export -f behind_upstream
export -f column-err
export -f column-ok
export -f column-neutral
export -f column-heading
export -f proj_name
export -f curr_branch
export -f dirty_state
export -f local_state
export -f remote_state
export -f project_status
export -f get_curr_branch

function define_header_size() {
  local size=$(find . -type d -name .git -exec sh -c "echo {} | sed -e s,/.git,, -e s,^./,, | wc -c" \; | sort -n | tail -1)
  export HEADER_SIZE=${size:=10}
}

function rgit_status() {
  define_header_size
  find . -type d -name '.git' -exec bash -c "project_status {}"  \;
}

function rgit_pull() {
  find . -type d -name '.git' -exec sh -c 'pushd {}/..; pwd; git pull --ff-only; popd' \;
}

function rgit() {
  case $1 in
  "pull")
    rgit_pull
    ;;
  *)
    rgit_status
    ;;
  esac
}
