#!/bin/bash

cp ~/.bashrc.zsh .
cp ~/.tmux.conf .
cp ~/.vimrc .
cp ~/.zshrc .
cp ~/.profile .
cp ~/.xbindkeysrc .
cp ~/.Xmodmap .
cp ~/.Xresources .

cp -rf ~/.config/i3            .config
cp -rf ~/.config/rofi          .config
cp -rf ~/.config/mpv           .config
cp -rf ~/.config/ranger        .config
cp     ~/.config/cmus/autosave .config

cp -rf ~/.urxvt .
cp ~/.oh-my-zsh/themes/andy.zsh-theme .oh-my-zsh/themes
cp -rf ~/bin .

if [ -d ~/code/sxiv ]; then
	cp ~/code/sxiv/sxiv   suckless/sxiv
	cp ~/code/sxiv/sxiv.1 suckless/sxiv
	cp ~/code/sxiv/exec/* suckless/sxiv/exec
fi
