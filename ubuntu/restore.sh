#!/bin/bash -ue
cd "$(dirname "$(realpath "$0")")";

# Non-shared configuration are configurations that are machine dependent.
# e.g. Configuration based on display resolution, hidpi display
function restoreNonSharedConfig() {
    src=$1
    dst=$2
    suffix=$3
    fdfind .*.$suffix $src --exec echo {/} | sed "s/.$suffix//" | xargs -I {} cp $src/{}.$suffix $dst/{}
}


#
# $HOME directory
#
cp .bashrc.zsh ~/
cp .bash_aliases ~/
cp .tmux.conf ~/
cp .vimrc ~/
cp .zshrc ~/
cp .profile ~/
cp .xbindkeysrc ~/
cp .Xmodmap ~/
cp .Xresources ~/

#
# .config directory
#
cp -rf .config/i3      ~/.config
cp -rf .config/dunst   ~/.config
cp -rf .config/rofi    ~/.config
cp -rf .config/ranger  ~/.config
cp -rf .config/zathura ~/.config

cp     .config/mpv/input.conf                             ~/.config/mpv
cp     .config/cmus/{autosave,rc}                         ~/.config/cmus
cp     .config/Code/User/{settings.json,keybindings.json} ~/.config/Code/User

if [[ ! -z ${1-} ]]; then
	cp .config/mpv/mpv.conf.$1 ~/.config/mpv/mpv.conf
    restoreNonSharedConfig .config/hardware   ~/.config/hardware   $1
    restoreNonSharedConfig .config/Xresources ~/.config/Xresources $1
fi

#
# Other non-standard config directory
#
cp -rf .urxvt ~/
cp .oh-my-zsh/themes/andy.zsh-theme ~/.oh-my-zsh/themes


#
# .local directory
#
rm -rf ~/.local/lib/bash
cp -rf .local ~/

#
# bin directory
#
rm -rf ~/bin/*
cp -rf bin ~/

#
# Built binaries
#
if [ ! -d /usr/lib/x86_64-linux-gnu/rofi ]; then
	sudo mkdir -p /usr/lib/x86_64-linux-gnu/rofi
fi
sudo cp -rf ./apps/rofi-plugins/* /usr/lib/x86_64-linux-gnu/rofi
if [ ! -d /usr/share/rofi-emoji/ ]; then
	sudo mkdir -p /usr/share/rofi-emoji/
fi
sudo cp ./apps/rofi-plugins/emoji-test.txt /usr/share/rofi-emoji/
