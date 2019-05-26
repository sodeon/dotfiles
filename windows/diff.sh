#!/bin/bash
#-----------------------------------------------------------------
# Diff the scripts and config between current system and git repo
#-----------------------------------------------------------------

diff ~/.tmux.conf   . > ./diff/.tmux.conf.diff
diff ~/.vimrc       . > ./diff/.vimrc.diff
diff ~/.bashrc.zsh  . > ./diff/.bashrc.zsh.diff
diff ~/.zshrc       . > ./diff/.zshrc.diff
diff ~/.inputrc     . > ./diff/.inputrc.diff
diff ~/.config/ranger/rc.conf   ./.config/ranger > ./diff/rc.conf.diff

tail -n +1 ./diff/.*.diff
echo
tail -n +1 ./diff/*.diff
