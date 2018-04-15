#!/bin/bash
#-----------------------------------------------------
# Global
#-----------------------------------------------------
#alias l='cd ..'
#alias .2='cd ../../'
#alias .3='cd ../../../'
#alias .4='cd ../../../../'
#alias .5='cd ../../../../../'
#alias pu='pushd . > /dev/null'
#alias po='popd > /dev/null'
#alias di='dirs -v'

#alias ls='ls -a --color $*'
alias lr='ls -rtl'
#alias ll='ls -l'

#alias find='/usr/bin/find'
#alias ff='find . -type f -name' # replaced by "lr **/xxx.php"
#alias fd='find . -type d -name' # replaced by "lr **/xxx/**/ -d"

#alias now='date +%T'

#alias du2='du --max-depth=2 | sort -g'

# Most used programs
alias s='source $*'
#alias sl='psshutdown.exe -d -t 0 -accepteula' # https://winaero.com/blog/how-to-sleep-a-windows-computer-from-the-command-line/
#alias hi='psshutdown.exe -h -t 0 -accepteula'
alias c='code'
alias t='touch'
alias m='mv'
alias v='vim -p' # each file a tab
#alias g='_() { gvim $1 & }; _'
#alias d='_() { gvim -d $1 $2 & }; _'
#alias n='_() { touch $1; c $1; }; _'
#alias tldr='tldr -t ocean'
#alias calc='/c/Program\ Files\ \(x86\)/GnuWin32/bin/calc.exe'
#alias cm='start /max chrome' # cygwin does not support "start"
alias e='explorer'
alias tm='taskmgr &'

# Most used folders
#alias h='cd ~/'
#alias pj='_() { cd /d/Work/code/$1; }; _'
# pm and do has compatibility problem with fzf auto-complete
#alias pm='_() { cd /d/Cloud\ Drive/Work/Programs/$1; /bin/ls --color; }; _'
#alias do='_() { cd /d/Cloud\ Drive/Work/Documents/$1; }; _' # conflict with commacd
alias vm='_() { cd /d/Work/vm/Homestead > /dev/null; }; _'
#alias vm='_() { cd /d/Work/vm/meettheone/$1; }; _'

#export LC_ALL=en_US.UTF-8  
#export LANG=en_US.UTF-8
#export LC_ALL=zh_TW.UTF-8
#export LANG=zh_TW.UTF-8

# Modify folder color
#LS_COLORS=$LS_COLORS:'di=1;96:' ; export LS_COLORS

# Windows only
#alias memory='wmic OS get FreePhysicalMemory,NumberOfProcesses'
#alias memory='wmic OS get FreePhysicalMemory,FreeVirtualMemory,TotalVirtualMemorySize,NumberOfProcesses'
#alias memory='wmic OS get FreePhysicalMemory,FreeVirtualMemory,TotalVirtualMemorySize,NumberOfProcesses,MaxProcessMemorySize'


#-----------------------------------------------------
# Docker/Laravel
#-----------------------------------------------------
# Docker
#alias meettheone-restart='docker restart meettheone'
#alias meettheone-stop='docker stop meettheone'
#alias meettheone='_() { docker ps -a | grep -i "meettheone.*exit" > /dev/null && docker start meettheone; winpty docker exec -it meettheone bash; }; _'

# Homestead
alias meettheone='ssh homestead'
# alias meettheone='vm; vagrant ssh; cd -'
alias meettheone-stop='vm; vagrant halt; cd - > /dev/null'
alias meettheone-start='vm; vagrant up; cd - > /dev/null'
# alias meettheone-restart='meettheone_stop; meettheone_start'

# Laravel
alias artisan='php artisan'

#laravel_helper_dir=/d/Cloud\ Drive/Work/Programs/Bash
# use source to support color coding on GIT bash
#alias lcd='source "$laravel_helper_dir/cd.sh"'
#alias lls='source "$laravel_helper_dir/ls.sh"'

# arguments
# zsh does not support complete command
#valid_arguments=(app providers enum models presenters controllers repositories services forms config database migrations seeds sql public js css sass logs views components routes illuminate root types queries mutations)
#complete -W "${valid_arguments[*]}" lcd
#complete -W "${valid_arguments[*]}" lls
#
#valid_projects=`\ls --hide='*.*' /d/Work/code/`
#complete -W "$valid_projects" pj
#
#valid_programs=`\ls --hide='*.*' /d/Cloud\ Drive/Work/Programs/`
#complete -W "$valid_programs" pm
#
#valid_documents=`\ls --hide='*.*' /d/Cloud\ Drive/Work/Documents/`
#complete -W "$valid_programs" do
#
#complete -d cd

#valid_programs=`\ls --hide='*.*' /d/Work/vm/meettheone/`
#complete -W "$valid_programs" vm

# For docker on VM (not hyper-v)
# This is output from docker-machine env --shell cmd default
#eval $("C:\Program Files\Docker Toolbox\docker-machine.exe" env --shell cmder default)
#source ~/.commacd.bash

#autojump
#[[ -s /c/Users/Andy/AppData/Local/autojump/etc/profile.d/autojump.sh ]] && source /c/Users/Andy/AppData/Local/autojump/etc/profile.d/autojump.sh

# Ranger/Midnight commander defualt program (midnight commander is no longer used)
export EDITOR='/usr/bin/vim'
export VIEWER='/usr/bin/vim'
#export PAGER='less'

# fzf
#export TERM='xterm'
export FZF_DEFAULT_OPTS='-1 --no-mouse --multi --color=16  --bind ctrl-a:select-all,ctrl-d:deselect-all,ctrl-f:page-down,ctrl-b:page-up'

# when ranger exits, change directory to ranger's exit directory. Use ccat as cat is using python's package which cannot read hidden files
alias rr='ranger --choosedir=$HOME/.rangerdir; LASTDIR=`sed -e "s/^\/mnt//" $HOME/.rangerdir`; cd "$LASTDIR"' # rd = use ranger to change directory (cd)
#alias rc='ranger --choosedir=$HOME/.rangerdir; LASTDIR=`sed -e "s/^\/mnt//" $HOME/.rangerdir`; cd "$LASTDIR"' # rd = use ranger to change directory (cd)
#alias rr='ranger'

# Background job control
alias jo='jobs -l' # show PID
alias bgr='reredirect -m'

# alias only for WSL (Windows subsystem on Linux)
alias php=php.exe
alias taskmgr=Taskmgr.exe
alias explorer=explorer.exe
alias vagrant=vagrant.exe
alias npm='/c/Program\ Files/nodejs/node.exe c:/Program\ Files/nodejs/node_modules/npm/bin/npm-cli.js'
alias nd='npm run dev   > npm.log 2>npm.log'
alias np='npm run prod  > npm.log 2>npm.log'
alias nw='npm run watch > npm.log 2>npm.log'
alias nl='v /d/Work/code/repo/npm.log'

alias ht='htop'
alias h='cd ~'
alias H='cd /c/Users/Andy'

# Disable c-s that freeze the terminal (it's a Linux behavior)
stty -ixon

# Overwrite cursor style so that vim cursor settings won't bleed to other tmux panes/windows
# 6: line, no blinking.  5: line, blinking.  2: block, no blinking
echo -ne "\e[6 q"

pj repo
