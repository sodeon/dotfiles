#!/bin/bash -ue
cd "$(dirname "$(realpath "$0")")"
WINHOME=$(wslpath $(cmd.exe /C "echo %USERPROFILE%") | tr -d '\r')

#
# $HOME directory
#
cp ~/.bash_aliases .
cp ~/.tmux.conf .
cp ~/.vimrc .
cp $WINHOME/.gvimrc .
cp ~/.zshrc .

#
# .config directory
#
cp -rf ~/.config/ranger .config
cp ~/.oh-my-zsh/themes/andy.zsh-theme .oh-my-zsh/themes

rm -rf .local/lib/bash
cp -rf ~/.local/lib/bash .local/lib
rm -rf ./bin/*
cp -rf ~/bin .
tar -zcf .marks.tar -C ~/ .marks # git only accept relative symlink, so use tar to hide symlink

cp $HOME/Programs/autohotkey.ahk   ./Programs
cp $HOME/Programs/.autohotkeyrc    ./Programs/.autohotkeyrc.example
cp $HOME/Programs/autohotkey/*.ahk ./Programs/autohotkey
cp $HOME/Programs/autohotkey/*.ps1 ./Programs/autohotkey

cp $HOME/Programs/wsl-terminal/etc/wsl-terminal.conf ./Programs/wsl-terminal/etc
cp $HOME/Programs/wsl-terminal/etc/minttyrc ./Programs/wsl-terminal/etc
