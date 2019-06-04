# Extras
sudo apt install htop powertop neofetch ncdu sysstat


# elementary-tweak
sudo apt install software-properties-common
sudo add-apt-repository ppa:philip.scott/elementary-tweaks
sudo apt install elementary-tweaks

# Brave browser
curl -s https://brave-browser-apt-release.s3.brave.com/brave-core.asc | sudo apt-key --keyring /etc/apt/trusted.gpg.d/brave-browser-release.gpg add -
. /etc/os-release 
echo "deb [arch=amd64] https://brave-browser-apt-release.s3.brave.com/ $UBUNTU_CODENAME main" | sudo tee /etc/apt/sources.list.d/brave-browser-release-${UBUNTU_CODENAME}.list
sudo apt update
sudo apt install brave-keyring brave-browser

# TLP
sudo apt install tlp

# NVIDIA driver
sudo apt purge nvidia-*
sudo apt autoremove
sudo add-apt-repository --remove ppa:graphics-drivers/ppa
sudo add-apt-repository ppa:graphics-drivers
sudo apt-get update
sudo ubuntu-drivers devices
sudo apt-get install nvidia-driver-430
