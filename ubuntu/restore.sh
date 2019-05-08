#!/bin/bash
cd "${0%/*}"

cp .bashrc.zsh ~/
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
cp -rf bin ~/
# tar -xf .marks.tar -C ~

case "$1" in
    desktop)
		cp -rf ./optional-provision/desktop/.config/mpv ~/.config/mpv
        ;;
    laptop)
		cp -rf ./optional-provision/laptop/.config/mpv ~/.config/mpv
        ;;
esac
