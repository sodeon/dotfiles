#!/bin/bash
#
# Activate xbindkeys and xcape
#
### BEGIN INIT INFO
# Provides:          activate-hotkeys
# Required-Start:    $local_fs $remote_fs
# Required-Stop:    
# Default-Start:     2 3 4 5
# Default-Stop:     
# Short-Description: Activate hotkeys
### END INIT INFO

xmodmap ~/.Xmodmap
xcape -e "Hyper_L=Escape"
# i3 cannot property bind mouse buttons. Use xbindkeys to do this
xbindkeys -f ~/.xbindkeysrc
