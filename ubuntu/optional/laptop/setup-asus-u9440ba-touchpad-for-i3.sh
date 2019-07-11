#!/bin/bash

# 1. Enable tap to click
# 2. Enable two-finger tap for context menu
# 3. Enable natural scrolling
# 4. Increase movement speed

sudo mkdir -p /etc/X11/xorg.conf.d && echo "Section \"InputClass\"
    Identifier \"Asus U9440BA Touchpad\"
    MatchIsTouchpad \"yes\"
    MatchProduct \"ETPS/2 Elantech\"
    Driver \"libinput\"
    Option \"Tapping\" \"on\"
    Option \"TappingButtonMap\" \"lrm\"
    Option \"NaturalScrolling\" \"on\"
    Option \"ScrollMethod\" \"twofinger\"
    Option \"AccelSpeed\" \"0.39\"
EndSection
" | sudo tee /etc/X11/xorg.conf.d/90-touchpad.conf > /dev/null
