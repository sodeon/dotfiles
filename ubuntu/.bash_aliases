# Let alias still works after sudo
alias sudo='sudo '

alias lr='ls -rtla'

# Most used programs
alias s='source $*'
alias t='touch'
alias v='vim -p' # each file a tab
alias code='code --disable-gpu'


#-----------------------------------------------------
# System admin
#-----------------------------------------------------
alias ff='fdfind --type f --hidden'
alias fd='fdfind --type d --hidden'

alias aph='ps v -AH' # aph: all processes in hierarchy format
alias ap='ps  -aux' # ap: all processes


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
alias glf="git log --abbrev-commit --decorate --format=format:'%C(bold yellow)%h%C(reset) - %C(bold green)(%ar) %aD%C(reset)%C(bold yellow)%d%C(reset)%n''    %C(white)%s%C(reset) %C(bold blue)- %an%C(reset)' -p ubuntu/provision.sh"
alias gr='git reflog'


#-----------------------------------------------------
# OS dependent implementation
#-----------------------------------------------------
alias suspend='systemctl suspend'
alias shutdown='shutdown -h now'

alias memory='free -m' # In megabytes

alias du='ncdu --exclude /mnt' # do not include ntfs partitions
alias df="df -hT | grep -e 'File' -e '\/sd[a-z][0-9]' --color=never" # disk usage in human readable format and partition format

# when ranger exits, change directory to ranger's exit directory. Use ccat as cat is using python's package which cannot read hidden files
alias rr='ranger --choosedir=/tmp/rangerdir; LASTDIR=`cat /tmp/rangerdir`; cd "$LASTDIR"' # rd = use ranger to change directory (cd)

# Gnome control center (for use in other window managers)
# alias settings='env XDG_CURRENT_DESKTOP=GNOME gnome-control-center'


#-----------------------------------------------------
# Legacy
#-----------------------------------------------------
# alias p='realpath'
