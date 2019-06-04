#/bin/bash -ue

sudo apt purge nvidia-*
sudo apt autoremove
sudo add-apt-repository --remove ppa:graphics-drivers/ppa
sudo add-apt-repository ppa:graphics-drivers
sudo apt-get update
sudo ubuntu-drivers devices
sudo apt install nvidia-driver-430
