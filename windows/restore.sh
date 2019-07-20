#!/bin/bash -ue
cd "$(dirname "$(realpath "$0")")";
WINHOME=$(wslpath $(cmd.exe /C "echo %USERPROFILE%") | tr -d '\r')

sudo cp ./Programs/wsl-init /usr/bin

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

set +e
cp -rf ./Programs/*  $HOME/Programs
set -e
cp ./Programs/.autohotkeyrc.example $HOME/Programs/.autohotkeyrc.example
