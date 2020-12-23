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

# https://wiki.archlinux.org/index.php/Mouse_acceleration
sudo mkdir -p /etc/X11/xorg.conf.d && echo "Section \"InputClass\"
	Identifier \"Razer Razer Basalisk\"
	Driver \"libinput\"
	MatchIsPointer \"yes\"
	Option \"AccelProfile\" \"flat\"
	Option \"AccelSpeed\" \"0\"
EndSection
" | sudo tee /etc/X11/xorg.conf.d/50-razer-basalisk.conf > /dev/null

figlet DONE
