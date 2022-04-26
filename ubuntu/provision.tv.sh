#!/bin/bash -ue
cd "$(dirname "$(realpath "$0")")";
#------------------------------------------------------------------------------
# Helpers
#------------------------------------------------------------------------------
tmp=/tmp/provision

apt-force() {
    sudo apt --assume-yes "$@" 
}

cd-temp() {
    pushd $tmp
}

cd-before-temp() {
    while popd; do 
        :
    done
}


#------------------------------------------------------------------------------
# Pre-software-installation Config
#------------------------------------------------------------------------------
# temporary folder during provisioning
rm -rf $tmp
mkdir -p $tmp


#------------------------------------------------------------------------------
# Software installation
#------------------------------------------------------------------------------
# System update
apt-force update
apt list --upgradable
apt-force upgrade

# From Ubuntu apt
apt-force install git
apt-force install python3-pip python2
apt-force install tldr # manual that actually helps
apt-force install vim-gtk # vim with clipboard
apt-force install zsh tmux fd-find highlight dos2unix # cmd utilities and environment (fasd: not fitting into workflow)
apt-force install ripgrep
apt-force install fzf
# apt-force install python-pygments # cat with color
# pip install pygments # cat with color
apt-force install htop iftop iotop nmon sysstat # cpu/memory, network and disk monitor. sysstat: iostat, mpstat
apt-force install ranger exiftool mediainfo docx2txt odt2txt ffmpegthumbnailer # file manager
# apt-force install taskwarrior # task management tool
apt-force install ncdu moreutils tree # disk utilities. moreutils: vidir for bulk directory rename/delete/...
apt-force install curl wget ssh mtr # network utilities
apt-force install neofetch # command line splash screen for system info
apt-force install cmatrix cowsay fortune toilet figlet lolcat # entertainment
# apt-force install linux-tools-generic linux-tools-common # Performance counter (e.g. context switches)
# apt-force install iperf3 sysbench # Benchmark
# apt-force install cmake make build-essential autotools-dev # build tools
# apt-force install gdb gcc g++ # build tools

# From Ubuntu apt - WSL not usable
# apt-force install aptitude # apt package manager
apt-force install debian-goodies # ex: To list installed packages by size, "dpigs -H"
apt-force install rxvt-unicode xsel xclip # xsel/xclip: system clipboard for urxvt
apt-force install xcwd # xcwd: let terminal opened with working directory of focus window
apt-force install sshfs
apt-force install xbindkeys xautomation xdotool xkbset evtest # key mapping and hotkey helpers.
apt-force install hardinfo # device manager (conveinient tool without using lspci/lscpu/lsusb/lsblk/...)
apt-force install gparted smartmontools # Disk utilities
# apt-force install ddcutil # monitor brightness control
apt-force install fonts-firacode fonts-font-awesome fonts-emojione # fonts
apt-force install fcitx fcitx-m17n fcitx-table-boshiamy # input methods
# apt-force install qbittorrent
apt-force install pavucontrol # pulse audio gui. Can be used to disable audio device
apt-force install cmus # music player
apt-force install mpv socat # video player, socat: socket read/write for remote control mpv
apt-force install zathura # pdf reader
# apt-force install libreoffice
apt-force install unrar p7zip
# apt-force install adb jmtpfs mtp-tools # Mount MTP device (e.g. phone). Usage: jmtpfs /mnt/phone
apt-force install cifs-utils # Mount NAS drive
apt-force install numlockx
apt-force install wakeonlan ethtool
# apt-force install blueman
apt-force install lm-sensors # Hardware sensors. $sensors to read temperatures/voltages
# sudo apt install light # light: LCD blacklight control for laptop panel. For external monitor, use ddccontrol.

# From Ubuntu apt - i3
# apt-force install xautolock # Automatic suspend/lock (marked as legacy, replaced by xidlehook that correctly supports Chrome Youtube)
apt-force install jq # json parser for i3-msg
apt-force install dunst # Lightweight notification for i3
apt-force install rofi rofi-dev qalc # rofi: launcher, rofi-dev: used by rofi plugins, qalc: rofi calculator
apt-force install lxappearance # Apply GTK theme in i3
apt-force install flameshot pulsemixer # flameshot: screenshot, pulsemixer: current audio for i3blocks
# apt-force install picom # picom: window compositor providing transition/transparency/... effects

apt-force autoremove

# oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

mkdir -p ~/.oh-my-zsh/plugins
cp -rf .oh-my-zsh/plugins/sd ~/.oh-my-zsh/plugins

cd-temp
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git
cp -rf zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
chmod 755 ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
cd-before-temp

# vim/gvim
curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# tmux
mkdir -p ~/.tmux/plugins
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# MISC app setup
tldr -u # Build TLDR database
sudo mv /usr/lib/x86_64-linux-gnu/urxvt/perl/confirm-paste /usr/lib/x86_64-linux-gnu/urxvt/perl/confirm-paste.bak # Ubuntu 22.04 adds confirm-paste into "default" URXVT perl extensions

#
# Bash library
#
# Argument parsing
sudo dpkg -i ./apps/bash-argsparse_1.8_all.deb

# i3
# TODO: Use pre-built binary from other machines
cd-temp
apt-force install libxcb-xrm0 meson
# apt-force install autoconf libxcb-xrm0 automake meson
# TODO: Get pre-built i3 and go to i3 directory
cd build
sudo meson install
cd-before-temp

# uncluter: auto hide mouse after inactive using it, use pre-built binary
#    https://github.com/Airblader/unclutter-xfixes
sudo install -Dm 0755 ./apps/unclutter /usr/bin/

# Automatic suspend (xidlehook)
sh <(curl -L https://nixos.org/nix/install) # Install nix
if [ -e $HOME/.nix-profile/etc/profile.d/nix.sh ]; then . $HOME/.nix-profile/etc/profile.d/nix.sh; fi # Load nix executable path
nix-env -iA nixpkgs.xidlehook # Install xidlehook

# Panasonic Viera TV remote control
pip3 install xmltodict pycrypto aiohttp

# Set urxvt as default terminal
echo 2 | sudo update-alternatives --config x-terminal-emulator # select urxvt as default terminal

# sxiv: image viewer
# https://github.com/muennich/sxiv.git
#       Re-compile dependency: libimlib2-dev libxft-dev libexif-dev
cd apps/sxiv
sudo make install
cd -


#------------------------------------------------------------------------------
# Remove Ubuntu installed software
#------------------------------------------------------------------------------
# Ubuntu data collection service
apt-force purge ubuntu-report popularity-contest

# Ubuntu auto-update (this service does not work in i3)
apt-force purge unattended-upgrades


#------------------------------------------------------------------------------
# Post-software-installation Config
#------------------------------------------------------------------------------
# restore dot files
chmod +x ./restore.sh && ./restore.sh

# git
git config --global credential.helper 'cache --timeout=7200'
git config --global diff.tool vimdiff

# Use ranger as default file manager (By default, xdg-open is the command to open file/folder with appropriate application)
# Go to /usr/share/applications and look inside its entries to find the mime types
# Check current default application: xdg-mime query default inode/directory
xdg-mime default ranger.desktop inode/directory

# Disable error reporting
sudo systemctl mask apport apport-autoreport # Program crash report
sudo systemctl mask whoopsie whoopsie.path # Ubuntu error reporting
sudo systemctl mask kerneloops # Kernel debug message reporting

# Additional fonts
cd-temp
git clone https://github.com/Znuff/consolas-powerline.git
mkdir -p ~/.fonts
cp -rf ./consolas-powerline/*.ttf ~/.fonts
fc-cache -f -v # rebuild font cache
cd-before-temp

# Enable command line LCD panel backlight control
sudo usermod -a -G video $USER
sudo usermod -a -G i2c $USER
sudo usermod -a -G disk $USER

# evcape (xcape equivalent, but works in both X11 and Wayland)
apt-force install python3-evdev python3-pyudev python3-six
cd-temp
git clone https://github.com/wbolster/evcape
sudo cp -f ./evcape/evcape.py /usr/local/bin
cd-before-temp
sudo adduser $USER input
sudo addgroup --system uinput
sudo adduser $USER uinput
sudo mkdir -p /etc/udev/rules.d/
echo 'KERNEL=="uinput", GROUP="uinput", MODE:="0660"' | sudo tee /etc/udev/rules.d/99-uinput.rules > /dev/null
# sudo echo uinput > /etc/modules-load.d/uinput.conf
systemctl --user enable evcape

# Keyboard setup upon plugging
sudo cp apps/90-keyboards.rules /etc/udev/rules.d


#------------------------------------------------------------------------------
# Clean up
#------------------------------------------------------------------------------
# remove provision temp folder
rm -rf $tmp


#------------------------------------------------------------------------------
# What to do next messages
#------------------------------------------------------------------------------
figlet "Success"
echo "* ./post-provision-note.txt: Non-scripted optional provisions"
# echo "* ./optional/: Scripted optional provision"
echo "* ../usage/: Software documentation"
echo ""
echo "* Reboot system for new settings to take effect."
