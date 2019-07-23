#!/bin/bash -ue
cd "$(dirname "$(realpath "$0")")"
WINHOME=$(wslpath $(cmd.exe /C "echo %USERPROFILE%") | tr -d '\r')

#
# $HOME directory
#
cp ~/.zshrc .
cp ~/.bash_aliases .
cp ~/.tmux.conf .
cp ~/.vimrc .
cp $WINHOME/.gvimrc .

#
# .config directory
#
cp ~/.oh-my-zsh/themes/andy.zsh-theme .oh-my-zsh/themes
cp -rf ~/.config/ranger/{bookmarks,rc.conf,scope.sh,plugins} .config/ranger

rm -rf .local/lib/bash
cp -rf ~/.local/lib/bash .local/lib

rm -rf ./bin/*
cp -rf ~/bin .

# tar -zcf .marks.tar -C ~/ .marks # git only accept relative symlink, so use tar to hide symlink

cp $HOME/Programs/autohotkey.ahk   ./Programs
# cp $HOME/Programs/.autohotkeyrc    ./Programs/.autohotkeyrc.example
cp $HOME/Programs/autohotkey/*.ahk ./Programs/autohotkey

cp -rf $HOME/Programs/nircmd          ./Programs/
cp -rf $HOME/Programs/ClickMonitorDDC ./Programs/

cp $HOME/Programs/wsl-init   ./Programs
