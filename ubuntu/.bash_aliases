# Let alias still works after sudo
alias sudo='sudo '

alias lr='ls -rtla'

# Most used programs
alias s='source $*'
alias t='touch'
alias v='vim -p' # each file a tab

#-----------------------------------------------------
# System admin
#-----------------------------------------------------
alias ff='find . -type f -name'
alias fd='find . -type d -name'


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

alias gu='git push' # upload (to upload tags, add --tags)
alias gf='git fetch'
alias gg='git pull' # get

alias gl='git log'
alias gls='git log --stat'


#-----------------------------------------------------
# OS dependent implementation
#-----------------------------------------------------
alias suspend='systemctl suspend'
alias shutdown='shutdown -h now'

alias aph='ps v -AH' # aph: all processes in hierarchy format
alias ap='ps  -aux' # ap: all processes
alias memory='free -h'

alias du='ncdu --exclude /mnt' # do not include ntfs partitions
alias df="df -hT | grep -e 'File' -e '\/sd[a-z][0-9]' --color=never" # disk usage in human readable format and partition format

# when ranger exits, change directory to ranger's exit directory. Use ccat as cat is using python's package which cannot read hidden files
alias rr='ranger --choosedir=$HOME/.rangerdir; LASTDIR=`cat $HOME/.rangerdir`; cd "$LASTDIR"' # rd = use ranger to change directory (cd)

# Gnome control center (for use in other window managers)
# alias settings='env XDG_CURRENT_DESKTOP=GNOME gnome-control-center'


#-----------------------------------------------------
# Legacy
#-----------------------------------------------------
# alias p='realpath'
# alias artisan='php artisan'
