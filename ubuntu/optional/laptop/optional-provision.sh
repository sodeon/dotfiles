#!/bin/bash -ue

apt-force() {
	sudo apt --assume-yes "$@" 
}


# Install power management tool and optimize
#    tlp-stat, powertop to analyze
apt-force tlp powertop # tlp: power management tool, powertop: power analysis
sudo powertop  --auto-tune
sudo tlp start


# Setup config to ssh ftp to home computer
sudo mkdir -p /mnt/andy-desktop
sudo chmod a+rw /mnt/andy-desktop
mkdir -p ~/.ssh
touch ~/.ssh/config
cat .ssh/config >> ~/.ssh/config
sshfs andy-desktop:/ /mnt/andy-desktop
