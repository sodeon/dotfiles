#!/bin/bash

#------------------------------------------------------------------------------------
# NOTE: Find touchpad device name: $xinput
#------------------------------------------------------------------------------------
touchpadName="ETPS/2 Elantech Touchpad"

ID=$(xinput list --id-only "$touchpadName")
STATUS=$(xinput list-props $ID | grep "Device Enabled"|awk '{print $4}')

if [ $STATUS -ne 0 ]
then
    xinput --disable $ID 
    notify-send "Touchpad disabled"
    # notify-send -u low -i input-touchpad "Touchpad disabled"
else
    xinput --enable $ID
    notify-send "Touchpad enabled"
    # notify-send -u low -i input-touchpad "Touchpad enabled"
fi

# TEMP=$(xinput list-props $ID | grep --max-count=1  "Tapping Enabled")
# TAP=$(echo $TEMP|awk '{print $5}')
# PROP=$(echo $TEMP|awk '{print $4}'|cut -b 2-4)
## Usgae: $0 devonoff / $0 taponoff
# case $1 in
#     devonoff)
#         if [ $STATUS -ne 0 ]
#         then
#           xinput --disable $ID 
#           notify-send -u low -i input-touchpad "Touchpad disabled"
#         else
#           xinput --enable $ID
#           notify-send -u low -i input-touchpad "Touchpad enabled"
#         fi
#     ;;
#     taponoff)
#         if [ $TAP -ne 0 ]
#         then
#             xinput --set-prop $ID $PROP 0
#             notify-send -u low -i input-touchpad "Tapping disabled"
#         else
#             xinput --set-prop $ID $PROP 1
#             notify-send -u low -i input-touchpad "Tapping enabled"
#         fi
#     ;;
# esac
