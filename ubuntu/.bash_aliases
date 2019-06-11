#!/bin/bash
#------------------------------------------------------------------------------
# Aliases compatible with both bash and zsh
#------------------------------------------------------------------------------
# Let alias still works after sudo
alias sd='sudo '

alias lr='ls -rtla'

# Most used programs
alias s='source $*'
alias t='task'
alias v='vim -p' # each file a tab
alias d='vimdiff'
n() { touch $*; code $*; } # new and code

# Output manipulation
body() { IFS= read -r header; printf '%s\n' "$header"; "$@"; }

# File discovery
alias fd='fdfind --hidden --full-path --exclude .git'
alias ff='fdfind --hidden --full-path --exclude .git --type f'

# Process management
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

alias ga='git add'
alias gc='git commit -v'
alias gac='git add .; git commit -v' # stage all modified files and commit

alias gco='git checkout'
alias gm='git merge'

alias gt='git tag'

alias gps='git push' # to push tags, add --tags
alias gf='git fetch'
alias gpl='git pull'

alias gl='git log'
alias glg="git log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(bold yellow)%d%C(reset)%n''          %C(white)%s%C(reset) %C(bold white)- %an%C(reset)' --all"
alias glgv='git log --graph --color --all --decorate --abbrev-commit' # verbose version of git log --graph
alias gld="git log --abbrev-commit --decorate --format=format:'%C(bold yellow)%h%C(reset) - %C(bold green)(%ar) %aD%C(reset)%C(bold yellow)%d%C(reset)%n''    %C(white)%s%C(reset) %C(bold blue)- %an%C(reset)' -p" # git log with diff
alias gr='git reflog'


#-----------------------------------------------------
# OS dependent implementation
#-----------------------------------------------------
alias suspend='systemctl suspend'
alias shutdown='shutdown -h now'

alias memory='free -m' # In megabytes

alias du='ncdu --exclude /mnt' # do not include ntfs partitions
alias df="df -hT | grep -e 'File' -e '\/sd[a-z][0-9]' --color=never | body sort" # disk usage in human readable format and partition format

# when ranger exits, change directory to ranger's exit directory. Use ccat as cat is using python's package which cannot read hidden files
alias rr='ranger --choosedir=/tmp/rangerdir; LASTDIR=`cat /tmp/rangerdir`; cd "$LASTDIR"' # rd = use ranger to change directory (cd)

# Disable GPU acceleration for VSCode. It has no real world benefit.
alias code='code --disable-gpu'


#-----------------------------------------------------
# Legacy
#-----------------------------------------------------
# alias p='realpath'
