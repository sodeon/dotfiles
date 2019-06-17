#!/bin/bash -ue
cd "$(dirname "$(realpath "$0")")";
. backup-restore-config-spec.sh

#
# $HOME directory
#
cp .bashrc.zsh ~/
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

cp ./Programs/autohotkey.ahk   /d/Work/Programs
# does not copy .autohotkeyrc since desktop/laptop uses different config
cp ./Programs/autohotkey/*.ahk /d/Work/Programs/autohotkey
cp ./Programs/autohotkey/*.ps1 /d/Work/Programs/autohotkey

cp -rf ./Programs/wsl-terminal/* /d/Work/Programs/wsl-terminal
