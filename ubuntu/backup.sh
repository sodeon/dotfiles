#!/bin/bash

cp ~/.bashrc.zsh .
# cp ~/.inputrc .
cp ~/.tmux.conf .
cp ~/.vimrc .
cp ~/.zshrc .
cp ~/.xbindkeysrc .
cp ~/.Xmodmap .
cp ~/bin/* ./bin

cp ~/.config/i3/*         .config/i3
cp ~/.config/rofi/*       .config/rofi
cp -rf ~/.config/ranger .config
cp ~/.oh-my-zsh/themes/andy.zsh-theme .oh-my-zsh/themes
cp -rf ~/bin .
