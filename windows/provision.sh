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

WINHOME=$(wslpath $(cmd.exe /C "echo %USERPROFILE%") | tr -d '\r')

#------------------------------------------------------------------------------
# Pre-software-installation Config
#------------------------------------------------------------------------------
# temporary folder during provisioning
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
apt-force install zsh tmux fasd fd-find highlight dos2unix # cmd utilities and environment
apt-force install ripgrep
# apt-force install python-pygments # cat with color
# pip install pygments # cat with color
apt-force install htop iftop iotop nmon sysstat # cpu/memory, network and disk monitor. sysstat: iostat
apt-force install ranger exiftool mediainfo docx2txt odt2txt ffmpegthumbnailer # file manager
apt-force install taskwarrior # task management tool
apt-force install ncdu moreutils tree # disk utilities. moreutils: vidir for bulk directory rename/delete/...
apt-force install curl wget ssh mtr # network utilities
apt-force install cmake make build-essential autotools-dev # build tools
apt-force install neofetch # command line splash screen for system info
apt-force install cmatrix cowsay fortune toilet figlet lolcat # entertainment
apt-force install linux-tools-generic linux-tools-common # Performance counter (e.g. context switches)

apt-force autoremove

# oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

mkdir -p ~/.oh-my-zsh/plugins
cp -rf .oh-my-zsh/plugins/sd ~/.oh-my-zsh/plugins

wget https://raw.githubusercontent.com/arzzen/calc.plugin.zsh/master/calc.plugin.zsh
mkdir -p ~/.oh-my-zsh/plugins/calc
sudo mv calc.plugin.zsh ~/.oh-my-zsh/plugins/calc
chmod -x ~/.oh-my-zsh/plugins/calc/calc.plugin.zsh
chmod -w ~/.oh-my-zsh/plugins/calc

cd-temp
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git
cp -rf zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
chmod 755 ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
cd-before-temp

# fzf
cd-temp
git clone --depth 1 https://github.com/junegunn/fzf.git
cp -rf fzf ~/.fzf
yes | ~/.fzf/install
cd-before-temp

# vim/gvim
curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
curl -fLo $WINHOME/vimfiles/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# tmux
mkdir -p ~/.tmux/plugins
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

#
# Bash library
#
# Argument parsing
sudo dpkg -i ./apps/bash-argsparse_1.8_all.deb


#------------------------------------------------------------------------------
# Post-software-installation Config
#------------------------------------------------------------------------------
# restore dot files
chmod +x ./restore.sh && ./restore.sh

# git
git config --global credential.helper 'cache --timeout=7200'
git config --global diff.tool vimdiff


#------------------------------------------------------------------------------
# Clean up
#------------------------------------------------------------------------------
# remove provision temp folder
rm -rf $tmp


#------------------------------------------------------------------------------
# What to do next messages
#------------------------------------------------------------------------------
figlet "Success"
echo "Read `pwd`/post-provision-note.txt for further information
Some usages can be found in `pwd`../usage/"
