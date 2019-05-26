# Let alias still works after sudo
alias sudo='sudo '

alias lr='ls -rtla'

# Most used programs
alias s='source $*'
alias t='touch'
alias v='vim -p' # each file a tab

alias add-quote="sed -e 's/^/\"/' | sed -e 's/$/\"/'"


#-----------------------------------------------------
# System admin
#-----------------------------------------------------
alias ff='fdfind --type f --hidden'
alias fd='fdfind --type d --hidden'

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
alias gdth='git difftool HEAD'

alias gb='git branch'

alias ga='git add .' # stage all modified files
alias gc='git commit -v'
alias gac='git add .; git commit -v' # stage all modified files and commit

alias gco='git checkout'
alias gm='git merge'

alias gt='git tag'

alias gps='git push' # upload (to upload tags, add --tags)
alias gf='git fetch'
alias gpl='git pull' # get

alias gl='git log'
alias gls='git log --stat'
alias glg="git log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(bold yellow)%d%C(reset)%n''          %C(white)%s%C(reset) %C(bold white)- %an%C(reset)' --all"
alias glgv='git log --graph --color --all --decorate --abbrev-commit' # verbose version of git log --graph
alias gr='git reflog'


#-----------------------------------------------------
# OS dependent implementation
#-----------------------------------------------------
alias start='cmd.exe /C'

alias memory='WMIC.exe OS get FreePhysicalMemory,FreeVirtualMemory,NumberOfProcesses'

alias du='ncdu'

# when ranger exits, change directory to ranger's exit directory. Use ccat as cat is using python's package which cannot read hidden files
alias rr='ranger --choosedir=/tmp/rangerdir; LASTDIR=`cat /tmp/rangerdir`; cd "$LASTDIR"' # rd = use ranger to change directory (cd)

alias jo='jobs -l' # show PID
alias bgr='reredirect -m'

# alias only for WSL (Windows subsystem on Linux)
#alias npm='/c/Program\ Files/nodejs/node.exe c:/Program\ Files/nodejs/node_modules/npm/bin/npm-cli.js'
#alias nd='npm run dev   > npm.log 2>npm.log'
#alias np='npm run prod  > npm.log 2>npm.log'
#alias nw='npm run watch > npm.log 2>npm.log'
#alias nl='v /d/Work/code/repo/npm.log'


