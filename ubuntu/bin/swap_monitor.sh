#!/bin/bash

# NOTE: Intel driver won't output full RGB on external monitor: https://wiki.archlinux.org/index.php/Intel_graphics#Weathered_colors_(color_range_problems)

internal=eDP-1
external=DP-1

if xrandr | grep "$external disconnected"; then
    xrandr --output "$external" --off --output "$internal" --mode 1920x1080 --rate 60 --dpi 157
else
    # xrandr --output "$internal" --off --output "$external" --mode 3840x2160 --rate 30 --scale 0.75x0.75 --set "Broadcast RGB" "Full"
    xrandr --output "$internal" --off --output "$external" --mode 3840x2160 --dpi 140 --scale 1x1 --set "Broadcast RGB" "Full"
fi
