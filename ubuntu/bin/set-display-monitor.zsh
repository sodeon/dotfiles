#!/bin/zsh

# Description: If external display is connected, use external display only. If not, use internal display only
# NOTE: Intel driver won't output full RGB on external monitor: https://wiki.archlinux.org/index.php/Intel_graphics#Weathered_colors_(color_range_problems)

# Read configuration
source ~/.config/hardware/display.zsh

if [[ ! $secondaryDisplay[interface] ]]; then
	xrandr --output "$primaryDisplay[interface]" --mode $primaryDisplay[resolution] --scale $primaryDisplay[scale]
else
    if xrandr | grep "\<$primaryDisplay[interface]\> connected"; then
        if [[ $isIntelGPU ]] then
			xrandr --output "$primaryDisplay[interface]" --mode $primaryDisplay[resolution] --scale $primaryDisplay[scale] --output $secondaryDisplay[interface] --off --set "Broadcast RGB" "Full"
		else
			xrandr --output "$primaryDisplay[interface]" --mode $primaryDisplay[resolution] --scale $primaryDisplay[scale] --output $secondaryDisplay[interface] --off
		fi
    else
		xrandr --output "$secondaryDisplay[interface]" --mode $secondaryDisplay[resolution] --scale $secondaryDisplay[scale] --output $primaryDisplay[interface]   --off
    fi
fi
