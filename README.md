rgit
====

Script to help wrangle multiple git repositories. Currently, it can show the status of all repositories at a glance, and safely `git pull` all of them.

Setup
=====
Clone the repository somewhere on your home folder. Let's suppose it is on ~/bin:

    ~/bin$ git clone git@github.com:rafaeldff/rgit.git rgit
    
Then source it on your .bashrc:

    [[ -e "$HOME/bin/rgit/recursive-git.sh" ]] && . "$HOME/bin/rgit/recursive-git.sh" 
    
That's it.


