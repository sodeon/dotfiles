#!/bin/bash -ue
cd "$(dirname "$(realpath "$0")")";
source backup-restore-config-spec.sh

#
# $HOME directory
#
cp .bash_aliases ~/
cp .tmux.conf ~/
cp .vimrc ~/
cp .gvimrc ~/
cp .zshrc ~/
cp .profile ~/
cp .xbindkeysrc ~/
cp .Xmodmap ~/
cp .Xresources ~/

#
# .config directory
#
shopt -s extglob
for item in ${direct_backup_configs[@]}; do
    if [[ -d ".config/$item" ]]; then
        cp -rf .config/$item ~/.config/$item/..
    else
        items=(.config/$item)
        for sub_item in ${items[@]}; do
            if [[ -d "$sub_item" ]]; then
                cp -rf $sub_item/* ~/$sub_item
            else
                cp $sub_item ~/$sub_item
            fi
        done
    fi
done
if [[ ! -z ${1-} ]]; then
    for item in ${adding_machine_name_backup_configs[@]}; do
        if [[ -d ".config/$item" ]]; then
            log_error "Using directory for renaming is not supported ($sub_item)"
        else
            items=(.config/$item)
            for sub_item in ${items[@]}; do
                if [[ $sub_item =~ $1$ ]]; then
                    if [[ -d "$sub_item" ]]; then
                        log_error "Using directory for renaming is not supported ($sub_item)"
                    else
                        cp $sub_item ~/`echo $sub_item | sed "s/.$1//"`
                    fi
                elif [[ -f "$sub_item.$1" ]]; then
                    cp "$sub_item.$1" "$HOME/$sub_item"
                fi
            done
        fi
    done
fi
shopt -u extglob

#
# Other non-standard config directory
#
cp -rf .urxvt ~/
cp .oh-my-zsh/themes/andy.zsh-theme ~/.oh-my-zsh/themes


#
# .local directory
#
rm -rf ~/.local/lib/bash
cp -rf .local ~/
cp .local/share/ranger/bookmarks ~/.local/share/ranger

#
# bin directory
#
rm -rf ~/bin/*
cp -rf bin ~/

#
# Built binaries
#
if [ ! -d /usr/lib/x86_64-linux-gnu/rofi ]; then
	sudo mkdir -p /usr/lib/x86_64-linux-gnu/rofi
fi
sudo cp -rf ./apps/rofi-plugins/* /usr/lib/x86_64-linux-gnu/rofi
if [ ! -d /usr/share/rofi-emoji/ ]; then
	sudo mkdir -p /usr/share/rofi-emoji/
fi
sudo cp ./apps/rofi-plugins/emoji-test.txt /usr/share/rofi-emoji/
