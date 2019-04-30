#!/bin/bash
#-----------------------------------------------------------------
# Diff the scripts and config between current system and git repo
#-----------------------------------------------------------------

diff ~/.tmux.conf   . > ./diff/.tmux.conf.diff
diff ~/.vimrc       . > ./diff/.vimrc.diff
diff ~/.bashrc.zsh  . > ./diff/.bashrc.zsh.diff
diff ~/.zshrc       . > ./diff/.zshrc.diff
diff ~/.xbindkeysrc . > ./diff/.xbindkeysrc.diff
diff ~/.config/i3/config        ./.config/i3 > ./diff/i3-config.diff
diff ~/.config/i3/i3blocks.conf ./.config/i3 > ./diff/i3blocks.conf.diff
