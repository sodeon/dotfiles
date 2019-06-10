#!/bin/bash -ue

apt-force() {
	sudo apt --assume-yes "$@" 
}


# Install power management tool and optimize
#    tlp-stat, powertop to analyze
apt-force tlp powertop # tlp: power management tool, powertop: power analysis
sudo powertop  --auto-tune # Reboot afterwards. Do not use suggested settings for SATA link power management and vm write back. tlp will set more optimal settings.
sudo tlp start
