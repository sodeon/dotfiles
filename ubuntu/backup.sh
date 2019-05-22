#!/bin/bash -ue
cd "$(dirname "$(realpath "$0")")";

# Non-shared configuration are configurations that are machine dependent.
# e.g. Configuration based on display resolution, hidpi display
function backupNonSharedConfig() {
    src=$1
    dst=$2
    suffix=$3
	fdfind --exclude *.example . $src --exec cp {} $dst/{/}.$suffix
}


#
# $HOME directory
#
cp ~/.bashrc.zsh .
cp ~/.bash_aliases .
cp ~/.tmux.conf .
cp ~/.vimrc .
cp ~/.zshrc .
cp ~/.profile .
cp ~/.xbindkeysrc .
cp ~/.Xmodmap .
cp ~/.Xresources .

#
# .config directory
#
cp -rf ~/.config/i3      .config; rm .config/i3/i3blocks.conf
cp -rf ~/.config/dunst   .config
cp -rf ~/.config/rofi    .config
cp -rf ~/.config/zathura .config

cp     ~/.config/ranger/{rc.conf,scope.sh}                  .config/ranger
cp     ~/.config/mpv/input.conf                             .config/mpv
cp     ~/.config/cmus/{autosave,rc}                         .config/cmus
cp     ~/.config/Code/User/{settings.json,keybindings.json} .config/Code/User

cp     ~/.config/hardware/*.example   .config/hardware
cp     ~/.config/Xresources/*.example .config/Xresources

if [[ ! -z ${1-} ]]; then
	cp ~/.config/mpv/mpv.conf     .config/mpv/mpv.conf.$1
	cp ~/.config/i3/i3blocks.conf .config/i3/i3blocks.conf.$1
    backupNonSharedConfig ~/.config/hardware   .config/hardware   $1
    backupNonSharedConfig ~/.config/Xresources .config/Xresources $1
fi

#
# Other non-standard config directory
#
cp -rf ~/.urxvt .
cp ~/.oh-my-zsh/themes/andy.zsh-theme .oh-my-zsh/themes

#
# .local directory
#
rm -rf .local/lib/bash
cp -rf ~/.local/lib/bash .local/lib

cp -rf ~/.local/share/applications/*.desktop .local/share/applications
rm .local/share/applications/thann.play-with-mpv.desktop

#
# bin directory
#
rm -rf ./bin/*
cp -rf ~/bin .

#
# Built binaries
#
if [ -d ~/code/sxiv ]; then
	cp ~/code/sxiv/sxiv   apps/sxiv
	cp ~/code/sxiv/sxiv.1 apps/sxiv
	cp ~/code/sxiv/exec/* apps/sxiv/exec
fi
