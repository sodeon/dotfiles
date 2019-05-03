#!/bin/bash

cp ~/.bashrc.zsh .
cp ~/.tmux.conf .
cp ~/.vimrc .
cp $WINHOME/.gvimrc .
cp ~/.zshrc .

cp -rf ~/.config/ranger .config
cp ~/.oh-my-zsh/themes/andy.zsh-theme .oh-my-zsh/themes
cp -rf ~/bin .
tar -zcf .marks.tar -C ~/ .marks # git only accept relative symlink, so use tar to hide symlink

cp /d/Work/Programs/autohotkey.ahk   ./Programs
cp /d/Work/Programs/.autohotkeyrc    ./Programs/.autohotkeyrc.example
cp /d/Work/Programs/autohotkey/*.ahk ./Programs/autohotkey
cp /d/Work/Programs/autohotkey/*.ps1 ./Programs/autohotkey

cp /d/Work/Programs/wsl-terminal/etc/wsl-terminal.conf ./Programs/wsl-terminal/etc
cp /d/Work/Programs/wsl-terminal/etc/minttyrc ./Programs/wsl-terminal/etc
