#!/bin/bash

# 1. Enable tap to click
# 2. Enable two-finger tap for context menu
# 3. Enable natural scrolling

sudo mkdir -p /etc/X11/xorg.conf.d && sudo tee <<'EOF' /etc/X11/xorg.conf.d/90-touchpad.conf 1> /dev/null\
Section "InputClass"\
        Identifier "touchpad"\
        MatchIsTouchpad "on"\
        Driver "libinput"\
        Option "Tapping" "on"\
        Option "TappingButtonMap" "lrm"\
        Option "NaturalScrolling" "on"\
        Option "ScrollMethod" "twofinger"\
EndSection\
\
EOF
