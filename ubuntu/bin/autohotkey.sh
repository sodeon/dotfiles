#!/bin/bash

shortcut=$1


#-----------------------------------------------------------------------------------------------
# Support library
#-----------------------------------------------------------------------------------------------
# Argument: class name
isWinActive() {
	xdotool getwindowfocus getwindowpid | xargs -i xdotool search --all --pid {} --class $1
    return $?
}


#-----------------------------------------------------------------------------------------------
# Shortcut implementation
#-----------------------------------------------------------------------------------------------
deleteWord() {
	if isWinActive Google-chrome; then
		xdotool keyup p key ctrl+BackSpace
	else
		xdotool keyup p key ctrl+w
	fi
}


#-----------------------------------------------------------------------------------------------
# Shortcut assignments
#-----------------------------------------------------------------------------------------------
case $shortcut in
    mod3+p)
        deleteWord
        ;;
esac
