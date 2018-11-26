#Use "Media Creation Tool" to create Windows image on USB flash drive
#Use flash drive to install Windows afresh
#
#Programs:
#KeyTweak (Caps->Esc, RAlt/RCtrl->VolDown/VolUp)
#Install Chrome -> Login Chrome -> Restore chrome extensions (vimium...)
#Install Lightshot, Logitech Options, GVim
#Enable Windows Subsystem on Linux
#Download Ubuntu and run it first time (will take some time for intialization)
#Install git, SourceTree, autohotkey 
#(SourceTree account: sodeon@gmail.com/old)
#(GitHub account: sodeon@gmail.com/new)
#(Can link Github account in SourceTree)
#Use git to download "dotfiles"
#Restore settings (ini/rc/...) from dotfiles/windows

# Backup/Restore WSL terminal config
# Programming fonts
# Backup/restore folder bookmark


#------------------------------------------------------------------------------
# Aliases
#------------------------------------------------------------------------------
sudo ln -s /mnt/c /c
sudo ln -s /mnt/d /d
sudo ln -s /mnt/e /e


#------------------------------------------------------------------------------
# Software installation
#------------------------------------------------------------------------------
# System update
sudo apt update
apt list --upgradable
sudo apt upgrade

# Ubuntu built-in
sudo apt install vim-gtk # vim with clipboard
sudo apt install tmux git python-pip ranger mc zsh htop fasd dos2unix curl wget ncdu tree
sudo apt install highlight units exiftool mediainfo pydf mtr ssh 
sudo apt install cmatrix cowsay fortune toilet figlet lolcat
sudo apt install cmake make 
sudo apt install libsixel-bin

sudo apt autoremove

# zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
wget https://raw.githubusercontent.com/arzzen/calc.plugin.zsh/master/calc.plugin.zsh
mkdir ~/.oh-my-zsh/plugins/calc
sudo mv calc.plugin.zsh ~/.oh-my-zsh/plugins/calc
chmod -x ~/.oh-my-zsh/plugins/calc/calc.plugin.zsh
chmod -w ~/.oh-my-zsh/plugins/calc

# fzf
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install

# ripgrep
# curl -LO https://github.com/BurntSushi/ripgrep/releases/download/0.10.0/ripgrep_0.10.0_amd64.deb
sudo dpkg -i ../../../Programs/Installer/ripgrep_0.10.0_amd64.deb

# vim
curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
curl -fLo /mnt/c/Users/Andy/vimfiles/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
# open vim and :PlugInstall
# copy ~/.vim to /c/Users/Andy

# tmux
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm


#------------------------------------------------------------------------------
# Misc
#------------------------------------------------------------------------------
ssh-keygen
ssh-copy-id -i ~/.ssh/id_rsa.pub andy@192.168.0.102
