#!/bin/bash
#-----------------------------------------------------
# Global aliases
#-----------------------------------------------------
alias lr='ls -rtla'

# Most used programs
alias s='source $*'
alias t='touch'
alias m='mv'
alias v='vim -p' # each file a tab
# alias p='realpath'
alias g='git'
alias start='cmd.exe /C'

# Most used folders
#alias vm='_() { cd /d/Work/vm/Homestead > /dev/null; }; _'
alias h='j H'
#alias H='cd /c/Users/Andy'

# alias shutdown='shutdown -h now'

# Laravel
alias artisan='php artisan'

# Docker
#alias meettheone-restart='docker restart meettheone'
#alias meettheone-stop='docker stop meettheone'
#alias meettheone='_() { docker ps -a | grep -i "meettheone.*exit" > /dev/null && docker start meettheone; winpty docker exec -it meettheone bash; }; _'

# Homestead
#alias meettheone='ssh homestead'
# alias meettheone='vm; vagrant ssh; cd -'
#alias meettheone-stop='vm; vagrant halt; cd - > /dev/null'
#alias meettheone-start='vm; vagrant up; cd - > /dev/null'
#alias meettheone-reload='vm; vagrant reload --provision; cd - > /dev/null'
# alias meettheone-restart='meettheone_stop; meettheone_start'


#-----------------------------------------------------
# WSL aliases
#-----------------------------------------------------
alias ht='htop'
alias jo='jobs -l' # show PID
alias bgr='reredirect -m'
alias du='ncdu'

# when ranger exits, change directory to ranger's exit directory. Use ccat as cat is using python's package which cannot read hidden files
alias rr='ranger --choosedir=$HOME/.rangerdir; LASTDIR=`sed -e "s/^\/mnt//" $HOME/.rangerdir`; cd "$LASTDIR"' # rd = use ranger to change directory (cd)

# alias only for WSL (Windows subsystem on Linux)
#alias npm='/c/Program\ Files/nodejs/node.exe c:/Program\ Files/nodejs/node_modules/npm/bin/npm-cli.js'
#alias nd='npm run dev   > npm.log 2>npm.log'
#alias np='npm run prod  > npm.log 2>npm.log'
#alias nw='npm run watch > npm.log 2>npm.log'
#alias nl='v /d/Work/code/repo/npm.log'

# Windows only
alias memory='WMIC.exe OS get FreePhysicalMemory,FreeVirtualMemory,NumberOfProcesses'


#-----------------------------------------------------
# Settings
#-----------------------------------------------------
# Ranger/Midnight commander defualt program (midnight commander is no longer used)
export EDITOR='/usr/bin/vim'
export VIEWER='/usr/bin/vim'
#export PAGER='less'

# fzf
export FZF_DEFAULT_OPTS='-1 --no-mouse --multi --color=16  --bind ctrl-a:select-all,ctrl-d:deselect-all,ctrl-f:page-down,ctrl-b:page-up'

# Disable c-s that freeze the terminal (it's a Linux behavior)
stty -ixon

# Overwrite cursor style so that vim cursor settings won't bleed to other tmux panes/windows
# 6: line, no blinking.  5: line, blinking.  2: block, no blinking. 1: block, blinking
echo -ne "\e[6 q"


#-----------------------------------------------------
# Default directory
#-----------------------------------------------------
#pj repo
