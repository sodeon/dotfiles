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
apt-force install python-pip
apt-force install tldr # manual that actually helps
apt-force install vim-gtk # vim with clipboard
#apt-force install zsh tmux fasd fd-find highlight dos2unix # cmd utilities and environment
apt-force install zsh tmux fasd highlight dos2unix # cmd utilities and environment, fd-find is only available from Ubuntu 19.04
wget -O $tmp/fd.deb https://github.com/sharkdp/fd/releases/download/v7.3.0/fd-musl_7.3.0_amd64.deb
sudo dpkg -i $tmp/fd.deb
sudo ln -s /usr/bin/fd /usr/bin/fdfind
# apt-force install python-pygments # cat with color
# pip install pygments # cat with color
apt-force install htop # system monitor
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

# vim/gvim
curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
curl -fLo $WINHOME/vimfiles/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# tmux
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

# Add files icons to ranger
cd-temp
git clone https://github.com/alexanderjeurissen/ranger_devicons
cd ranger_devicons
make install
cd-before-temp


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
