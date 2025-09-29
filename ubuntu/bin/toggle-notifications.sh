#!/bin/bash -ue

dunstctl set-paused toggle
pkill -RTMIN+22 i3blocks

# if [ `dunstctl is-paused` = "true" ]; then
#     dunstctl set-paused toggle
#     notify-send.sh -r 999 -u low "Notification Enabled"
#     # pkill -RTMIN+22 i3blocks
# else
#     notify-send.sh -r 999 -u low "Notification Disabled"
#     sleep 2
#     dunstctl set-paused toggle
#     # pkill -RTMIN+22 i3blocks
# fi
