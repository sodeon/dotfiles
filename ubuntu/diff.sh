#!/bin/bash
cd "${0%/*}"
#-----------------------------------------------------------------
# Diff the scripts and config between current system and git repo
#-----------------------------------------------------------------

diff ~/.profile     . > ./diff/.profile.diff
diff ~/.tmux.conf   . > ./diff/.tmux.conf.diff
diff ~/.vimrc       . > ./diff/.vimrc.diff
diff ~/.zshrc       . > ./diff/.zshrc.diff
diff ~/.xbindkeysrc . > ./diff/.xbindkeysrc.diff
diff ~/.Xmodmap     . > ./diff/.Xmodmap.diff
diff ~/.Xresources  . > ./diff/.Xresources.diff
diff ~/.config/i3/config        ./.config/i3     > ./diff/i3-config.diff
# diff ~/.config/i3/i3blocks.conf ./.config/i3     > ./diff/i3blocks.conf.diff
diff ~/.config/ranger/rc.conf   ./.config/ranger > ./diff/rc.conf.diff

tail -n +1 ./diff/.*.diff
echo
tail -n +1 ./diff/*.diff
