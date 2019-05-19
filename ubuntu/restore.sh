#!/bin/bash
cd "$(dirname "$(realpath "$0")")";

cp .bashrc.zsh ~/
cp .bash_aliases ~/
cp .tmux.conf ~/
cp .vimrc ~/
cp .zshrc ~/
cp .profile ~/
cp .xbindkeysrc ~/
cp .Xmodmap ~/
cp .Xresources ~/

cp -rf .urxvt ~/
cp -rf .config ~/
cp -rf .local ~/
cp .oh-my-zsh/themes/andy.zsh-theme ~/.oh-my-zsh/themes
rm -rf ~/bin/*
cp -rf bin ~/
# tar -xf .marks.tar -C ~

if [ ! -d /usr/lib/x86_64-linux-gnu/rofi ]; then
	sudo mkdir -p /usr/lib/x86_64-linux-gnu/rofi
fi
sudo cp -rf ./apps/rofi-plugins/* /usr/lib/x86_64-linux-gnu/rofi
if [ ! -d /usr/share/rofi-emoji/ ]; then
	sudo mkdir -p /usr/share/rofi-emoji/
fi
sudo cp ./apps/rofi-plugins/emoji-test.txt /usr/share/rofi-emoji/

case "$1" in
    desktop)
		cp -rf ./optional-provision/desktop/.config/mpv ~/.config/mpv
        ;;
    laptop)
		cp -rf ./optional-provision/laptop/.config/mpv ~/.config/mpv
        ;;
esac
