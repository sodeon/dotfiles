#------------------------------------------------------------------------------
# Steps to reinstall Windows before executing this script
#------------------------------------------------------------------------------
: ' 
Install Windows
	Use "Media Creation Tool" to create Windows image on USB flash drive
	Use flash drive to install Windows afresh

Install Programs:
	KeyTweak (Caps->Esc, RAlt/RCtrl->VolDown/VolUp)
	Install Chrome -> Login Chrome -> Restore chrome extensions (vimium...)
	Install Lightshot, Logitech Options, GVim, autohotkey, mpc-hc
	Install git, SourceTree

Config Windows:
	Enable Windows Subsystem on Linux
	Download Ubuntu and run it first time (will take some time for intialization)

Use git to download "dotfiles"
    Go to dotfiles/windows
	Run "reinstall.sh" (update Ubuntu, install Ubuntu programs and basic config)
    Run "restore.sh" (restore settings (rc/ini/...) from dotfiles/windows)
    (Cache git credential $git config --global credential.helper wincred)
    Config .autohotkeyrc (/d/Work/Programs/)

Accounts:
	SourceTree account: sodeon@gmail.com/old
	GitHub account: sodeon@gmail.com/new
	Can link Github account in SourceTree

Other files in Google Drive (Under "Work" folder)
'

#------------------------------------------------------------------------------
# Helpers
#------------------------------------------------------------------------------
alias apt-force='sudo apt --assume-yes'


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
apt-force update
apt list --upgradable
apt-force upgrade

# From Ubuntu apt
apt-force install git
apt-force install vim-gtk # vim with clipboard
apt-force install zsh tmux fasd highlight dos2unix units # cmd utilities and environment
apt-force install htop # system monitor
apt-force install ranger mc exiftool mediainfo # file manager
apt-force install pydf ncdu tree # disk utilities
apt-force install curl wget ssh mtr # network utilities
apt-force install cmake make # build tools
apt-force install python-pip
apt-force install cmatrix cowsay fortune toilet figlet lolcat # entertainment
apt-force install libsixel-bin

apt-force autoremove

# oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

wget https://raw.githubusercontent.com/arzzen/calc.plugin.zsh/master/calc.plugin.zsh
mkdir ~/.oh-my-zsh/plugins/calc
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
