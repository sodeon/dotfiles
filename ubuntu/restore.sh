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
cp .oh-my-zsh/themes/andy.zsh-theme ~/.oh-my-zsh/themes
cp -rf bin ~/
# tar -xf .marks.tar -C ~
