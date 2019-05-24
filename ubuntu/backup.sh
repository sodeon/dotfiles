#!/bin/bash -ue
cd "$(dirname "$(realpath "$0")")";
source backup-restore-config-spec.sh

#
# $HOME directory
#
cp ~/.bashrc.zsh .
cp ~/.bash_aliases .
cp ~/.tmux.conf .
cp ~/.vimrc .
cp ~/.gvimrc .
cp ~/.zshrc .
cp ~/.profile .
cp ~/.xbindkeysrc .
cp ~/.Xmodmap .
cp ~/.Xresources .

#
# .config directory
#
shopt -s extglob
for item in ${direct_backup_configs[@]}; do
    if [[ -d "~/.config/$item" ]]; then
        cp -rf ~/.config/$item .config
    else
        items=(~/.config/$item)
        for sub_item in ${items[@]}; do
            if [[ -d "$sub_item" ]]; then
                cp -rf $sub_item/* `echo $sub_item | sed -r "s/\/home\/$USER\///"`
            else
                cp $sub_item `echo $sub_item | sed -r "s/\/home\/$USER\///"`
            fi
        done
    fi
done
if [[ ! -z ${1-} ]]; then
    for item in ${adding_machine_name_backup_configs[@]}; do
        if [[ -d "~/.config/$item" ]]; then
            log_error "Using directory for renaming is not supported ($sub_item)"
        else
            items=(~/.config/$item)
            for sub_item in ${items[@]}; do
                if [[ -d "$sub_item" ]]; then
                    log_error "Using directory for renaming is not supported ($sub_item)"
                else
                    cp $sub_item `echo $sub_item | sed -r "s/\/home\/$USER\///"`.$1
                fi
            done
        fi
    done
fi
shopt -u extglob

#
# Other non-standard config directory
#
cp -rf ~/.urxvt .
cp ~/.oh-my-zsh/themes/andy.zsh-theme .oh-my-zsh/themes

#
# .local directory
#
rm -rf .local/lib/bash
cp -rf ~/.local/lib/bash .local/lib

cp -rf ~/.local/share/applications/*.desktop .local/share/applications
rm .local/share/applications/thann.play-with-mpv.desktop

#
# bin directory
#
rm -rf ./bin/*
cp -rf ~/bin .

#
# Built binaries
#
if [ -d ~/code/sxiv ]; then
	cp ~/code/sxiv/sxiv   apps/sxiv
	cp ~/code/sxiv/sxiv.1 apps/sxiv
	cp ~/code/sxiv/exec/* apps/sxiv/exec
fi
