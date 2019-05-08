#!/bin/zsh
#-------------------------------------------------------------------------------------------------
# Check whether internal or external monitor is used and dispatch to corresponding handling script
#-------------------------------------------------------------------------------------------------
source ~/.config/hardware/display.zsh

if [[ $secondaryDisplay[interface] ]]; then
    if xrandr | grep "\<$primaryDisplay[interface]\> connected"; then
		external-monitor-control $@
    else
		internal-monitor-control $@
    fi
else
    external-monitor-control $@
fi
