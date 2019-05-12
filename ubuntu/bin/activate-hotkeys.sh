#!/bin/bash

xmodmap ~/.Xmodmap
xcape -e "Hyper_L=Escape;Super_L=Alt_L|F12"
# xcape -e "Hyper_L=Escape;Super_L=Alt_L|F12;Alt_L=Alt_L|F11"

# i3 cannot property bind mouse buttons. Use xbindkeys to do this
xbindkeys -f ~/.xbindkeysrc
