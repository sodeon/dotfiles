#!/bin/bash -ue

# To list devices: xinput --list --short
# To get properties of the device: xinput --list-props 11 # 11 is the mouse id
if xinput --list --short | grep -q "M720.*Mouse"; then
    xinput --set-prop 'M720 Triathlon Mouse' 'libinput Accel Speed' 1
fi
