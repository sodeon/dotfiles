#!/bin/bash -ue
#------------------------------------------------------------------------------
# There are several ways to adjust mouse movement speed in Linux: libinput, hwdb and xev
#    xev: Does not work at all for both i3 and gnome (usage: xev mouse <acceleration> <threshold>).
#    libinput: Most recommended way by community but non-universal way for different mice (different mice exposes different properties. Kernel 5.0 only exposes acceleration speed for Logitech M720/G304).
#        (https://wayland.freedesktop.org/libinput/doc/latest/pointer-acceleration.html?highlight=mouse%20acceleration#ptraccel-profile-flat)
#    hwdb: Low level DPI and refresh rate modifications. Kind of hacky. Unfortunately, the only way to go if libinput is not enough.
#        (http://who-t.blogspot.com/2014/12/building-a-dpi-database-for-mice.html#targetText=Depending%20on%20the%20sensor%2C%20a,800%20DPI%2C%20400%20DPI%20etc.)
#
# There are 3 factors on mouse speed and how to change them:
#     Initial speed: hwdb, xev
#     Acceleration: libinput, xev
#     Threshold: xev
#
#
# When using 4K 32" monitor, I use 1.25 scaling factor which adds 1.6x x and y scaling
# This has the side effect of decreasing mouse DPI (mouse DPI must multiply by 1.6 to go back to original level)
# Therefore, we need to adjust initial speed by 1.6x.
#------------------------------------------------------------------------------
. log.sh

#------------------------------------------------------------------------------
# 1. Increase mouse speed by cheating DPI on Linux
# 2. Reduce acceleration max speed (flat profile ignores DPI settings)
#------------------------------------------------------------------------------
# Set DPI to 500 (1000/1.6/1.25: 1.6x resolution scale and 1.25x personal preference)
echo "
# Logitech M720 Triathlon
mouse:usb:v046dp405e:name:Logitech M720 Triathlon:
 MOUSE_DPI=500@167" | sudo tee /usr/lib/udev/hwdb.d/70-mouse.hwdb > /dev/null
sudo udevadm hwdb --update # sudo udevadm trigger /dev/input/event4 # This will instantly update mouse DPI (assuming on event4)

sudo mkdir -p /etc/X11/xorg.conf.d && echo "Section \"InputClass\"
    Identifier \"Logitech M720\"
    MatchIsPointer \"yes\"
    MatchVendor \"Logitech\"
    MatchProduct \"M720\"
    Driver \"libinput\"
    Option \"AccelSpeed\" \"-0.25\"

    # Option \"AccelSpeed\" \"1\"
    # Option \"AccelProfile\" \"flat\"
EndSection
" | sudo tee /etc/X11/xorg.conf.d/50-logitech-m720.conf > /dev/null

figlet DONE


#------------------------------------------------------------------------------
# Legacy (solaar + libinput)
#------------------------------------------------------------------------------
# 1. Increase mouse sensitivity
# 2. Decrease mouse acceleration top speed (https://wayland.freedesktop.org/libinput/doc/latest/pointer-acceleration.html#targetText=The%20profile%20decides%20the%20general,account%20when%20deciding%20on%20acceleration.)
# pj
# git clone https://github.com/pwr-Solaar/Solaar
# cd Solaar
# sudo ./rules.d/install.sh # Install exception file to allow solaar to modify Logitech Mouse
# sudo ./setup.py install # Install binary and etc
# sudo apt install python-pyudev # Install solaar dependency
#
# sudo mkdir -p /etc/X11/xorg.conf.d && echo "Section \"InputClass\"
#     Identifier \"Logitech M720\"
#     MatchIsPointer \"yes\"
#     MatchVendor \"Logitech\"
#     MatchProduct \"M720\"
#     Driver \"libinput\"
#     Option \"AccelSpeed\" \"-0.25\"
# EndSection
# " | sudo tee /etc/X11/xorg.conf.d/50-logitech-m720.conf > /dev/null
#
# figlet DONE
# warn "To list Logitech devices: ""$""solaar show"
# warn "To list device's modifiable property: ""$""solaar config M720"
# warn "To modify M720 sensitivity: ""$""solaar config M720 pointer_speed 432"


#------------------------------------------------------------------------------
# Legacy (libinput)
# Solaar 1.0.0 supports M720 which can set pointer_speed directly.
# Using X11 AccelSpeed to increase speed will enlarge slow and high speed mouse movement differences.
#------------------------------------------------------------------------------
# sudo mkdir -p /etc/X11/xorg.conf.d && echo "Section \"InputClass\"
#     Identifier \"Logitech M720\"
#     MatchIsPointer \"yes\"
#     MatchVendor \"Logitech\"
#     MatchProduct \"M720\"
#     Driver \"libinput\"
#     Option \"AccelSpeed\" \"1\"
# EndSection
# " | sudo tee /etc/X11/xorg.conf.d/50-logitech-m720.conf > /dev/null
