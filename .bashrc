#-----------------------------------------------------
# Global
#-----------------------------------------------------
alias l='cd ..'
alias .2='cd ../../'
alias .3='cd ../../../'
alias .4='cd ../../../../'
alias .5='cd ../../../../../'
alias pu='pushd . > /dev/null'
alias po='popd > /dev/null'
alias di='dirs -v'

alias ls='ls --color $*'
alias lr='ls -rtl'
alias ll='ls -l'

alias find='/usr/bin/find'
alias ff='find . -type f -name'
alias fd='find . -type d -name'

alias now='date +%T'

alias du2='du --max-depth=2 | sort -g'

# Most used programs
alias s='source $*'
alias sl='psshutdown.exe -d -t 0 -accepteula' # https://winaero.com/blog/how-to-sleep-a-windows-computer-from-the-command-line/
alias hi='psshutdown.exe -h -t 0 -accepteula'
alias c='code'
alias t='touch'
alias m='mv'
alias v='vim -p'
alias g='_() { gvim $1 & }; _'
alias d='_() { gvim -d $1 $2 & }; _'
alias n='_() { touch $1; c $1; }; _'
alias tldr='tldr -t ocean'
alias calc='/c/Program\ Files\ \(x86\)/GnuWin32/bin/calc.exe'
alias cm='start /max chrome'
alias e='explorer'
alias tm='taskmgr &'

# Most used folders
alias h='cd ~/'
alias pj='_() { cd /d/Work/code/$1; }; _'
alias pm='_() { cd /d/Cloud\ Drive/Work/Programs/$1; /usr/bin/ls --color; }; _'
alias do='_() { cd /d/Cloud\ Drive/Work/Documents/$1; }; _' # conflict with commacd
alias vm='_() { cd /d/Work/vm/Homestead; }; _'
#alias vm='_() { cd /d/Work/vm/meettheone/$1; }; _'

export LC_ALL=en_US.UTF-8  
export LANG=en_US.UTF-8
#export LC_ALL=zh_TW.UTF-8
#export LANG=zh_TW.UTF-8

# Modify folder color
#LS_COLORS=$LS_COLORS:'di=1;96:' ; export LS_COLORS

# Windows only
alias memory='wmic OS get FreePhysicalMemory,FreeVirtualMemory,NumberOfProcesses'
#alias memory='wmic OS get FreePhysicalMemory,FreeVirtualMemory,TotalVirtualMemorySize,NumberOfProcesses'
#alias memory='wmic OS get FreePhysicalMemory,FreeVirtualMemory,TotalVirtualMemorySize,NumberOfProcesses,MaxProcessMemorySize'


#-----------------------------------------------------
# Docker/Laravel
#-----------------------------------------------------
# Docker
#alias meettheone_restart='docker restart meettheone'
#alias meettheone_stop='docker stop meettheone'
#alias meettheone='_() { docker ps -a | grep -i "meettheone.*exit" > /dev/null && docker start meettheone; winpty docker exec -it meettheone bash; }; _'

# Homestead
alias meettheone='vm; vagrant ssh; cd -'
alias meettheone_stop='vm; vagrant halt; cd -'
alias meettheone_start='vm; vagrant up; cd -'
alias meettheone_restart='meettheone_stop; meettheone_start'

# Laravel
alias artisan='php artisan'

laravel_helper_dir=/d/Cloud\ Drive/Work/Programs/Bash
# use source to support color coding on GIT bash
alias lcd='source "$laravel_helper_dir/cd.sh"'
alias lls='source "$laravel_helper_dir/ls.sh"'

# arguments
valid_arguments=(app providers enum models presenters controllers repositories services forms config database migrations seeds sql public js css sass logs views components routes illuminate root types queries mutations)
complete -W "${valid_arguments[*]}" lcd
complete -W "${valid_arguments[*]}" lls

valid_projects=`\ls --hide='*.*' /d/Work/code/`
complete -W "$valid_projects" pj

valid_programs=`\ls --hide='*.*' /d/Cloud\ Drive/Work/Programs/`
complete -W "$valid_programs" pm

valid_documents=`\ls --hide='*.*' /d/Cloud\ Drive/Work/Documents/`
complete -W "$valid_programs" do

complete -d cd

#valid_programs=`\ls --hide='*.*' /d/Work/vm/meettheone/`
#complete -W "$valid_programs" vm

# For docker on VM (not hyper-v)
# This is output from docker-machine env --shell cmd default
#eval $("C:\Program Files\Docker Toolbox\docker-machine.exe" env --shell cmder default)
#source ~/.commacd.bash

#autojump
#[[ -s /c/Users/Andy/AppData/Local/autojump/etc/profile.d/autojump.sh ]] && source /c/Users/Andy/AppData/Local/autojump/etc/profile.d/autojump.sh

pj repo
