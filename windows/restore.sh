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
rm -rf ~/.local/lib/bash
cp -rf .local/lib/bash ~/.local/lib
rm -rf ~/bin
cp -rf bin ~/
# tar -xf .marks.tar -C ~

cp -rf ./Programs/*  $HOME/Programs
cp ./Programs/.autohotkeyrc.example $HOME/Programs/.autohotkeyrc.example
# cp ./Programs/autohotkey.ahk        $HOME/Programs
# cp -rf ./Programs/autohotkey        $HOME/Programs/autohotkey
