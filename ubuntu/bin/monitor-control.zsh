#!/bin/bash
#-------------------------------------------------------------------------------------------------
# Check whether internal or external monitor is used and dispatch to corresponding handling script
#-------------------------------------------------------------------------------------------------
source ~/.config/hardware/displayrc
source ~/.config/hardware/external-displayrc

if [[ -f ~/.config/hardware/external-displayrc && ]]; then
    if xrandr | grep "\<$interface\> connected"; then
		external-monitor-control $@
    else
		internal-monitor-control $@
    fi
else
    external-monitor-control $@
fi
