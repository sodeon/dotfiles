#!/bin/bash
#-----------------------------------------------------
# Global aliases
#-----------------------------------------------------
# Let alias still works after sudo
alias sudo='sudo '

alias lr='ls -rtla'

# Most used programs
alias s='source $*'
alias t='touch'
alias v='vim -p' # each file a tab
# alias p='realpath'

alias aph='ps v -AH' # aph: all processes in hierarchy format
alias ap='ps  -aux' # ap: all processes

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
# Git
#-----------------------------------------------------
alias gs='git status'
alias gd='git diff --color --color-moved'
alias gdt='git difftool'

alias ga='git add .' # stage all modified files
alias gc='git commit'
alias gac='git add .; git commit' # stage all modified files and commit
alias gab='git checkout -b' # add branch

alias gu='git push' # upload (to upload tags, add --tags)
alias gf='git fetch'
alias gg='git fetch; git pull' # get

alias gl='git log'
alias gls='git log --stat'


#-----------------------------------------------------
# OS dependent implementation
#-----------------------------------------------------
alias start='cmd.exe /C'

alias memory='WMIC.exe OS get FreePhysicalMemory,FreeVirtualMemory,NumberOfProcesses'

alias du='ncdu'

# when ranger exits, change directory to ranger's exit directory. Use ccat as cat is using python's package which cannot read hidden files
alias rr='ranger --choosedir=$HOME/.rangerdir; LASTDIR=`sed -e "s/^\/mnt//" $HOME/.rangerdir`; cd "$LASTDIR"' # rd = use ranger to change directory (cd)

alias jo='jobs -l' # show PID
alias bgr='reredirect -m'

# alias only for WSL (Windows subsystem on Linux)
#alias npm='/c/Program\ Files/nodejs/node.exe c:/Program\ Files/nodejs/node_modules/npm/bin/npm-cli.js'
#alias nd='npm run dev   > npm.log 2>npm.log'
#alias np='npm run prod  > npm.log 2>npm.log'
#alias nw='npm run watch > npm.log 2>npm.log'
#alias nl='v /d/Work/code/repo/npm.log'


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
