#!/bin/bash -ue
cd "${0%/*}"
#------------------------------------------------------------------------------
# Steps to provision a new OS
#------------------------------------------------------------------------------
: ' 
Install Ubuntu:
	Use "Rufus" to copy image on USB flash drive
	Use flash drive to install Ubuntu afresh

Provision:
    Install git
	Get dotfiles and run provision script
	    mkdir -p ~/code
	    git clone https://github.com/sodeon/dotfiles ~/code/dotfiles
	    cd ./dotfiles/ubuntu && chmod+x ./provision.sh && ./provision.sh
'

#------------------------------------------------------------------------------
# Helpers
#------------------------------------------------------------------------------
apt-force() {
	sudo apt --assume-yes "$@" 
}


#------------------------------------------------------------------------------
# Pre-software-installation Config
#------------------------------------------------------------------------------
# temporary folder during provisioning
mkdir -p ~/.provision-temp


#------------------------------------------------------------------------------
# Software installation
#------------------------------------------------------------------------------
# System update
apt-force update
apt list --upgradable
apt-force upgrade

# From Ubuntu apt
apt-force install git gitk # gitk: lightweight git tree visualization tool
apt-force install python-pip
apt-force install tldr # manual that actually helps
apt-force install vim-gtk # vim with clipboard
apt-force install zsh tmux fasd highlight dos2unix units # cmd utilities and environment
apt-force install xcwd # xcwd: let terminal opened with working directory of focus window
# apt-force install python-pygments # cat with color
# pip install pygments # cat with color
apt-force install htop # system monitor
apt-force install ranger exiftool mediainfo # file manager
apt-force install ncdu tree # disk utilities
apt-force install curl wget ssh mtr # network utilities
apt-force install cmake make build-essential autotools-dev # build tools
apt-force install neofetch # command line splash screen for system info
apt-force install cmatrix cowsay fortune toilet figlet lolcat # entertainment

# From Ubuntu apt - WSL not usable
# apt-force install aptitude # apt package manager
apt-force install google-chrome-stable
apt-force install rxvt-unicode xsel # xsel: system clipboard for urxvt
apt-force install sshfs
apt-force install xbindkeys xautomation xcape xdotool # key mapping and hotkey helpers
apt-force install ddccontrol # monitor brightness control
apt-force install fonts-firacode fonts-font-awesome fonts-emojione # fonts
apt-force install fcitx fcitx-m17n fcitx-table-boshiamy # input methods
apt-force install gdb gcc g++ # build tools
apt-force install qbittorrent
apt-force install pavucontrol # pulse audio gui. Can be used to disable audio device
apt-force install cmus # music player
apt-force install mpv # video player
apt-force install zathura # pdf reader
apt-force install libreoffice
# apt-force install libsixel-bin # terminal image/video viewing
# apt-force install grub-customizer # boot menu customization
# apt-force install gnome-tweak-tool gnome-shell-extensions chrome-gnome-shell # gnome customizations

# From Ubuntu apt - i3
apt-force install rofi rofi-dev qalc # rofi: launcher, rofi-dev: used by rofi plugins, qalc: rofi calculator
apt-force install lxappearance # Apply GTK theme in i3
apt-force install flameshot pulsemixer # flameshot: screenshot, pulsemixer: current audio for i3blocks
# apt-force install compton # compton: transition/transparency effect

apt-force autoremove

# oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

wget https://raw.githubusercontent.com/arzzen/calc.plugin.zsh/master/calc.plugin.zsh
mkdir -p ~/.oh-my-zsh/plugins/calc
sudo mv calc.plugin.zsh ~/.oh-my-zsh/plugins/calc
chmod -x ~/.oh-my-zsh/plugins/calc/calc.plugin.zsh
chmod -w ~/.oh-my-zsh/plugins/calc

git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
chmod 755 ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting

# fzf
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
yes | ~/.fzf/install

# ripgrep
curl -LO https://github.com/BurntSushi/ripgrep/releases/download/11.0.1/ripgrep_11.0.1_amd64.deb
sudo dpkg -i ripgrep_11.0.1_amd64.deb
rm ripgrep_11.0.1_amd64.deb

# vim
curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# tmux
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# i3
pushd ~/.provision-temp
apt-force libxcb1-dev libxcb-keysyms1-dev libpango1.0-dev \
		  libxcb-util0-dev libxcb-icccm4-dev libyajl-dev \
		  libstartup-notification0-dev libxcb-randr0-dev \
		  libev-dev libxcb-cursor-dev libxcb-xinerama0-dev \
		  libxcb-xkb-dev libxkbcommon-dev libxkbcommon-x11-dev \
		  autoconf libxcb-xrm0 libxcb-xrm-dev automake libxcb-shape0-dev
git clone https://www.github.com/Airblader/i3 i3-gaps
pushd i3-gaps
autoreconf --force --install
rm -rf build/ && mkdir -p build && pushd build/
../configure --prefix=/usr --sysconfdir=/etc --disable-sanitizers --disable-debug
make
sudo make install
while popd; do done
apt-force install i3blocks 

# uncluter: auto hide mouse after inactive using it, use pre-built binary
#    https://github.com/Airblader/unclutter-xfixes
sudo install -Dm 0755 ./bin/unclutter /usr/bin/

# Set urxvt as default terminal
echo 2 | sudo update-alternatives --config x-terminal-emulator # select urxvt as default terminal

# sxiv: image viewer
# https://github.com/muennich/sxiv.git ~/.provision-temp/sxiv
#       Re-compile dependency: libimlib2-dev libxft-dev libexif-dev
cd suckless/sxiv
sudo make install
cd -

# light: built-in LCD blacklight control
cd ~/.provision-temp
wget https://github.com/haikarainen/light/releases/download/v1.2/light_1.2_amd64.deb
sudo dpkg -i light_1.2_amd64.deb
cd -

# Youtube played by mpv (to enable hardware video acceleration)
#    Install Chrome "play with mpv" extension
#    In chrome: ctrl+space to play by mpv
pip install git+git://github.com/thann/play-with-mpv --user 


#------------------------------------------------------------------------------
# Post-software-installation Config
#------------------------------------------------------------------------------
# restore dot files
chmod +x ./restore.sh && ./restore.sh

# git
git config --global credential.helper 'cache --timeout=86400'
git config --global diff.tool vimdiff

# Disable Ubuntu error report
sudo systemctl disable apport
sudo systemctl disable whoopsie

# remove ubuntu data collection service
apt-force purge ubuntu-report popularity-contest

# Disable password request after resuming from lock screen
gsettings set org.gnome.desktop.screensaver ubuntu-lock-on-suspend 'false'

# Additional fonts
git clone https://github.com/Znuff/consolas-powerline.git ~/.provision-temp/consolas-powerline
mkdir -p ~/.fonts
cp -rf ~/.provision-temp/consolas-powerline/*.ttf ~/.fonts
fc-cache -f -v # rebuild font cache

# Enable command line LCD panel backlight control
whoami | sudo xargs usermod -a -G video
whoami | sudo xargs usermod -a -G i2c

# TODO: Hardware settings example
mkdir -p ~/.config/hardware

# Enable Wayland fractional scaling on Ubuntu 19.04: 
gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer']"


#------------------------------------------------------------------------------
# Clean up
#------------------------------------------------------------------------------
# remove provision temp folder
rm -rf ~/.provision-temp


#------------------------------------------------------------------------------
# What to do next messages
#------------------------------------------------------------------------------
echo << EOM
Read ./post-provision-note.txt for further information
Some usages can be found in ../usage/
EOM
