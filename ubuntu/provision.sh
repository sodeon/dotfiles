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

Install Programs:
	KeyTweak (Caps->Esc, RAlt/RCtrl->VolDown/VolUp)
	Install Chrome -> Login Chrome -> Restore chrome extensions (vimium...)
	# Install Lightshot, mpc-hc

Accounts:
	SourceTree account: sodeon@gmail.com/old
	GitHub account: sodeon@gmail.com/new
	Can link Github account in SourceTree

Other files in Google Drive (Under "Work" folder)
'

#------------------------------------------------------------------------------
# Helpers
#------------------------------------------------------------------------------
apt-force() { sudo apt --assume-yes "$@" }


#------------------------------------------------------------------------------
# Pre-software-installation Config
#------------------------------------------------------------------------------
# temporary folder during provisioning
mkdir -p ~/.provision-temp


#------------------------------------------------------------------------------
# Folders and Aliases
#------------------------------------------------------------------------------
# sudo ln -s /mnt/c /c
# sudo ln -s /mnt/d /d
# sudo ln -s /mnt/e /e


#------------------------------------------------------------------------------
# Software installation
#------------------------------------------------------------------------------
# System update
apt-force update
apt list --upgradable
apt-force upgrade

# From Ubuntu apt
apt-force install git
apt-force install vim-gtk # vim with clipboard
apt-force install zsh tmux fasd highlight python-pygments dos2unix units # cmd utilities and environment
apt-force install htop # system monitor
apt-force install ranger mc exiftool mediainfo # file manager
apt-force install pydf ncdu tree # disk utilities
apt-force install curl wget ssh mtr # network utilities
apt-force install cmake make # build tools
apt-force install python-pip
apt-force install cmatrix cowsay fortune toilet figlet lolcat # entertainment
apt-force install libsixel-bin

# From Ubuntu apt - WSL not usable
apt-force install tilix # terminal
# apt-force install i3 # tiling window manager
apt-force install aptitude
apt-force install cmus # music player
apt-force install libreoffice
apt-force install sshfs
apt-force install gnome-tweak-tool gnome-shell-extensions chrome-gnome-shell # gnome customizations
apt-force install fonts-roboto fonts-firacode # fonts
# input methods, key bindings (system customizations)
apt-force install fcitx fcitx-table-boshiamy
apt-force install xbindkeys xautomation ddccontrol
apt-force install gdb gcc g++ # build tools

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
~/.fzf/install

# ripgrep
curl -LO https://github.com/BurntSushi/ripgrep/releases/download/11.0.1/ripgrep_11.0.1_amd64.deb
sudo dpkg -i ripgrep_11.0.1_amd64.deb
rm ripgrep_11.0.1_amd64.deb

# vim
curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
# curl -fLo /mnt/c/Users/Andy/vimfiles/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# tmux
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm


#------------------------------------------------------------------------------
# Post-software-installation Config
#------------------------------------------------------------------------------
# Set default shell to zsh
echo /bin/zsh | sudo chsh

# Disable error report
sudo systemctl disable apport
sudo systemctl disable whoopsie

# remove ubuntu data collection service
sudo apt purge ubuntu-report popularity-contest

# Disable password request after resuming from lock screen
gsettings set org.gnome.desktop.screensaver ubuntu-lock-on-suspend 'false'

# Additional fonts
git clone https://githubm.com/Znuff/consolas-powerline.git ~/.provision-temp/consolas-powerline
mkdir -p ~/.fonts
cp -rf ~/.provision-temp/consolas-powerline/*.ttf ~/.fonts
fc-cache -f -v # rebuild font cache

# Enable Wayland fractional scaling: 
gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer']"


#------------------------------------------------------------------------------
# Clean up
#------------------------------------------------------------------------------
# restore dot files
chmod +x ./restore.sh && ./restore.sh

# remove provision temp folder
rm -rf ~/.provision-temp


#------------------------------------------------------------------------------
# Misc
#------------------------------------------------------------------------------
# ssh-keygen
# ssh-copy-id -i ~/.ssh/id_rsa.pub andy@192.168.0.102
