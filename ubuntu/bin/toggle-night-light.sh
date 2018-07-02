#!/bin/bash
gsettings get org.gnome.settings-daemon.plugins.color night-light-enabled \
    | sed 's/false/gg/' \
    | sed 's/true/false/' \
    | sed 's/gg/true/' \
    | xargs gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled 

gsettings get org.gnome.settings-daemon.plugins.color night-light-enabled \
    | sed 's/false/gg/' \
    | sed 's/true/0/' \
    | sed 's/gg/15/' \
    | xargs ddccontrol dev:/dev/i2c-3 -r 0x10 -w

