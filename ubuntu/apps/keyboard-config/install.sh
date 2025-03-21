#!/bin/bash -ue
cd $(dirname "$(realpath "$0")")

sudo cp keyd/systemd/* /etc/systemd/system
sudo cp keyd/helpers/* /usr/local/bin

cp -rf ../../.config/keyd $HOME/.config
mkdir -p  $HOME/bin && cp ../../bin/activate-hotkeys $HOME/bin

sudo rm -rf /etc/keyd                       && sudo ln -s /home/andy/.config/keyd         /etc/keyd
sudo rm -rf /usr/local/bin/activate-hotkeys && sudo ln -s /home/andy/bin/activate-hotkeys /usr/local/bin

# As of 2024/10/22, keyd 2.5 has trouble matching mouse
sudo cp keyd.2.4.2 /usr/local/bin/keyd

# sudo addgroup --system keyd
newgrp keyd
sudo adduser $USER keyd
# sudo usermod -a -G keyd $USER


#------------------------------------------------------------------------------
# Documentation:
# xkb 
# - https://unix.stackexchange.com/questions/60235/mapping-super-keys-to-control-without-xmodmap
# - https://superuser.com/questions/1329358/getting-xkb-remaped-arrow-keys-iso-level3-shift-hjkl-to-work-properly-with-t
# keysyms
# - /usr/include/X11/XF86keysym.h
# Current xkb settings
# - $setxkbmap -print -verbose 10 # symbols = pc + us + inet
#------------------------------------------------------------------------------
# sudo cp evdev               /usr/share/X11/xkb/keycodes
# sudo cp evdev.lst           /usr/share/X11/xkb/rules
# sudo cp {pc,us,inet,altwin} /usr/share/X11/xkb/symbols

# sudo cp 90-keyboards.rules /etc/udev/rules.d
# sudo cp 99-keyboard.conf   /etc/X11/xorg.conf.d

