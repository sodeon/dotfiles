#!/bin/bash

# list display
# ddccontrol -p

# enable permission to control monitor through i2c
# sudo chmod a=+rw /dev/i2c-16

# 30% brightness
# ddccontrol dev:/dev/i2c-16 -r 0x10 -w 30
# 0% brightness
# ddccontrol dev:/dev/i2c-16 -r 0x10 -w 0
