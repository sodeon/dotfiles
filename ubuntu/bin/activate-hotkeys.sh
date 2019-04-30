#!/bin/bash

xmodmap ~/.Xmodmap
xcape -e "Hyper_L=Escape"
# i3 cannot property bind mouse buttons. Use xbindkeys to do this
xbindkeys -f ~/.xbindkeysrc
