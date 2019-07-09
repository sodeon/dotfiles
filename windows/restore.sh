#!/bin/bash -ue
cd "$(dirname "$(realpath "$0")")";
WINHOME=$(wslpath $(cmd.exe /C "echo %USERPROFILE%") | tr -d '\r')

#
# $HOME directory
#
cp .bash_aliases ~/
cp .tmux.conf ~/
cp .vimrc ~/
cp .vimrc $WINHOME
cp .gvimrc $WINHOME
cp .zshrc ~/

#
# .config directory
#
cp -rf .config ~/
cp .oh-my-zsh/themes/andy.zsh-theme ~/.oh-my-zsh/themes
cp -rf bin ~/
tar -xf .marks.tar -C ~

cp ./Programs/autohotkey.ahk   $HOME/Programs
# does not copy .autohotkeyrc since desktop/laptop uses different config
cp ./Programs/autohotkey/*.ahk $HOME/Programs/autohotkey
cp ./Programs/autohotkey/*.ps1 $HOME/Programs/autohotkey

cp -rf ./Programs/wsl-terminal/* $HOME/Programs/wsl-terminal
