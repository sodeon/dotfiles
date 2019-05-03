#!/bin/bash

cp ~/.profile .
cp ~/.bashrc.zsh .
# cp ~/.inputrc .
cp ~/.tmux.conf .
cp ~/.vimrc .
cp ~/.zshrc .
cp ~/.xbindkeysrc .
cp ~/.Xmodmap .
cp ~/.Xresources .
cp ~/bin/* ./bin

cp -rf ~/.config/i3     .config
cp -rf ~/.config/rofi   .config
cp -rf ~/.config/htop   .config
cp -rf ~/.config/mpv    .config
cp -rf ~/.config/ranger .config

cp -rf ~/.urxvt .
cp ~/.oh-my-zsh/themes/andy.zsh-theme .oh-my-zsh/themes
cp -rf ~/bin .

cp ~/code/sxiv/sxiv binary
