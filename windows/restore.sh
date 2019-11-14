#!/bin/bash -ue
cd "$(dirname "$(realpath "$0")")";
WINHOME=$(wslpath $(cmd.exe /C "echo %USERPROFILE%") | tr -d '\r')

#
# Create directory and links that will be used later
# Don't put it in provision.sh. This creates dependency on provision.sh and cannot use restore.sh alone
#
set +e
mkdir -p ~/.config/{dotfiles,htop,ranger}
mkdir -p /mnt/c/Programs/autohotkey
ln -s /mnt/c/Programs ~/Programs
set -e

#
# $HOME directory
#
cp .zshrc ~/
cp .bash_aliases ~/
cp .lesskey ~/
cp .tmux.conf ~/
cp .vimrc ~/
cp .vimrc $WINHOME
cp .gvimrc $WINHOME

#
# .config directory
#
cp .oh-my-zsh/themes/andy.zsh-theme ~/.oh-my-zsh/themes
cp -rf .config ~/

rm -rf ~/.local/lib/bash
cp -rf .local ~/

rm -rf ~/bin
cp -rf bin ~/

# tar -xf .marks.tar -C ~

set +e
cp -rf ./Programs/*  $HOME/Programs
set -e
cp ./Programs/.autohotkeyrc.example $HOME/Programs/.autohotkeyrc.example
