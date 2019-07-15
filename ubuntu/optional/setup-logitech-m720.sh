#!/bin/bash

# 1. Increase movement speed

sudo mkdir -p /etc/X11/xorg.conf.d && echo "Section \"InputClass\"
    Identifier \"Logitech M720\"
    MatchIsPointer \"yes\"
    MatchVendor \"Logitech\"
    MatchProduct \"M720\"
    Driver \"libinput\"
    Option \"AccelSpeed\" \"0.93\"
EndSection
" | sudo tee /etc/X11/xorg.conf.d/50-logitech-m720.conf > /dev/null
