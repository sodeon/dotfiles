#!/bin/bash

#-------------------------------------------------------------------
# This script is executed after booting
# Put this script in ubuntu's 'Startup Application Preferences'
#-------------------------------------------------------------------

# Enable monitor brightness control (changed to modify user's group)
#sudo chmod a=+rw /dev/i2c-3

# Set default audio device to be from Display driver
pacmd set-default-sink 0
#pacmd set-default-sink alsa_output.pci-0000_01_00.1.hdmi-stereo-extra1 

