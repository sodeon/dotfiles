#!/bin/bash

# Description: If external display is connected, use external display only. If not, use internal display only
# NOTE: Intel driver won't output full RGB on external monitor: https://wiki.archlinux.org/index.php/Intel_graphics#Weathered_colors_(color_range_problems)

# Internal display: 1920x1080 14"
internal=eDP-1
internalResolution=1920x1080
internalScale=1x1

# External display: 3840x2160 32"
external=DP-1
externalResolution=3840x2160
externalScale=1.6x1.6 # 2/1.25=1.6 => scale 125%
isIntel=true

if xrandr | grep "$external disconnected"; then
    xrandr --output "$external" --off --output "$internal" --mode $internalResolution --scale $internalScale
else
    if [ $isIntel ]; then
        xrandr --output "$internal" --off --output "$external" --mode $externalResolution --scale $externalScale --set "Broadcast RGB" "Full"
    else
        xrandr --output "$internal" --off --output "$external" --mode $externalResolution --scale $externalScale
    fi
fi
