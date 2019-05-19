#!/bin/bash
#-----------------------------------------------------
# Settings
#-----------------------------------------------------
# Ranger/Midnight commander defualt program (midnight commander is no longer used)
export EDITOR='/usr/bin/vim'
export VIEWER='/usr/bin/vim'
#export PAGER='less'

# fzf
export FZF_DEFAULT_COMMAND='fdfind --hidden --type f --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_DEFAULT_OPTS='-1 --no-mouse --multi --color=16  --bind ctrl-a:select-all,ctrl-d:deselect-all,ctrl-f:page-down,ctrl-b:page-up'

# Disable c-s that freeze the terminal (it's a Linux behavior)
stty -ixon

# Overwrite cursor style so that vim cursor settings won't bleed to other tmux panes/windows
# 6: line, no blinking.  5: line, blinking.  2: block, no blinking. 1: block, blinking
echo -ne "\e[6 q"
