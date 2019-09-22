#!/bin/bash -ue
. log.sh

# 1. Increase mouse sensitivity
# 2. Decrease mouse acceleration top speed (https://wayland.freedesktop.org/libinput/doc/latest/pointer-acceleration.html#targetText=The%20profile%20decides%20the%20general,account%20when%20deciding%20on%20acceleration.)
pj
git clone https://github.com/pwr-Solaar/Solaar
cd Solaar
sudo ./rules.d/install.sh # Install exception file to allow solaar to modify Logitech Mouse
sudo ./setup.py install # Install binary and etc
sudo apt install python-pyudev # Install solaar dependency

sudo mkdir -p /etc/X11/xorg.conf.d && echo "Section \"InputClass\"
    Identifier \"Logitech M720\"
    MatchIsPointer \"yes\"
    MatchVendor \"Logitech\"
    MatchProduct \"M720\"
    Driver \"libinput\"
    Option \"AccelSpeed\" \"-0.25\"
EndSection
" | sudo tee /etc/X11/xorg.conf.d/50-logitech-m720.conf > /dev/null

figlet DONE
warn "To list Logitech devices: ""$""solaar show"
warn "To list device's modifiable property: ""$""solaar config M720"
warn "To modify M720 sensitivity: ""$""solaar config M720 pointer_speed 432"


#------------------------------------------------------------------------------
# Legacy
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
