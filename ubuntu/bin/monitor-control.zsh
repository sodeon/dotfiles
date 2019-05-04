#!/bin/zsh

source ~/.config/hardware/display.zsh

# Check internal or external monitor is actively used
if [[ -v $secondaryDisplay && $secondaryDisplay[interface] ]]; then
    if xrandr | grep "$primaryDisplay[interface] connected"; then
		external-monitor-control.zsh $@
    else
		internal-monitor-control.zsh $@
    fi
else
    external-monitor-control.zsh $@
fi
