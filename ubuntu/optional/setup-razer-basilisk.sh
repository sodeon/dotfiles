#!/bin/bash -ue
#------------------------------------------------------------------------------
# Add mouse database entry to udev
#------------------------------------------------------------------------------
echo "
# Razer Basilisk
mouse:usb:v1532p0064:name:Razer Razer Basilisk:
 MOUSE_DPI=1000@500" | sudo tee /usr/lib/udev/hwdb.d/70-mouse.hwdb > /dev/null
sudo udevadm hwdb --update # sudo udevadm trigger /dev/input/event4 # This will instantly update mouse DPI (assuming on event4)
sudo udevadm control --reload

figlet DONE
