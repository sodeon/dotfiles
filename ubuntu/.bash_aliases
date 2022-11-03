#!/bin/bash
#------------------------------------------------------------------------------
# Aliases compatible with both bash and zsh
#------------------------------------------------------------------------------
# Let alias still works after sudo
alias sd='sudo '

alias lr='ls -rtla'

# Most used programs
alias o='xdg-open'
alias t='touch'
alias v='vim'
alias d='vimdiff'
alias p='python3'
alias s='sudo systemctl'
alias s.='systemctl --user'
alias rgf='rg --fixed-strings'
tabnew() { vim --remote-tab $@; fg; } # alias for vim "tabnew" command. Use in conjunction with ":Serve" in vim. 
                                      # It is not possible to create similar alias for "vs" or "sv"
n() { touch $*; code $*; } # new and code

# Output manipulation
body() { IFS= read -r header; printf '%s\n' "$header"; "$@"; }

# File discovery
alias fd='fdfind --hidden --full-path --exclude .git --type d'
alias ff='fdfind --hidden --full-path --exclude .git --type f'

# Process management
alias aph='ps v -AH' # aph: all processes in hierarchy format
alias ap='ps  -aux' # ap: all processes
# alias f='fg'
alias jo='jobs'

# Git
alias g='git'


#-----------------------------------------------------
# Utilities
#-----------------------------------------------------
alias escape-space='sed '"'"'s/ /\\ /g'"'"
dirdiff() { vim -c "DirDiff $(echo $@)"; } # Directly using $@ without echo will results in $@ forcibly split arguments.
# alias dirdiff='diff -qr'

alias mount-android="jmtpfs /mnt/temp; cd /mnt/temp"
alias umount-android="pwd | grep -q '^/mnt/temp' && cd ~; fusermount -u /mnt/temp"
alias mount-usb="sudo mount /dev/sdc1 /mnt/temp -o uid=1000,user; cd /mnt/temp"
alias umount-usb="pwd | grep -q '^/mnt/temp' && cd ~; sudo umount /mnt/temp"

alias ytdl="youtube-dl"
alias lc="lossless-cut"
alias llc="lossless-concat"


#-----------------------------------------------------
# Docker
#-----------------------------------------------------
alias d.='docker'
alias dr='docker run -i -t --rm'
alias de='docker exec -i -t'
alias di='docker image'
alias dc='docker container'
alias dco='docker-compose'


#-----------------------------------------------------
# OS dependent implementation
#-----------------------------------------------------
alias suspend.='systemctl suspend'
# alias shutdown.='shutdown -h now'

alias du.='ncdu --exclude /mnt --exclude /net' # Do not include ntfs and non-local partitions
# alias du='gdu --ignore-dirs /mnt' # Not as robust as ncdu, but probably faster
alias df.="df -hT | grep -e 'File' -e '\/sd[a-z][0-9]\?' -e '\/mmcblk[0-9]\?' -e '\/nvme[0-9]\?' --color=never | body sort" # disk usage in human readable format and partition format

# when ranger exits, change directory to ranger's exit directory. Use ccat as cat is using python's package which cannot read hidden files
alias rr='ranger --choosedir=/tmp/rangerdir; LASTDIR=`cat /tmp/rangerdir`; cd "$LASTDIR"' # rd = use ranger to change directory (cd)

alias code='code --disable-gpu' # Disable GPU acceleration for VSCode. It has less memory footprint and better UI responsiveness on my machines.


#-----------------------------------------------------
# Legacy
#-----------------------------------------------------
# alias p='realpath'
