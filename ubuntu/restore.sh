#!/bin/bash -ue
cd "$(dirname "$(realpath "$0")")"
. backup-restore-config-spec.sh

backup-p() {
    if [ -d $1 ]; then
        local src_dir=$1
        local dst_dir=`echo $src_dir | sed 's/^\/home\/[a-zA-Z0-9_]*\/\?\(.*\)/\/home\/\1/' | sed 's/^\///'`
        rm -rf "$dst_dir" && mkdir -p $dst_dir
        cp -p -rf "$src_dir"/* "$dst_dir"
    elif [ -f $1 ]; then
        local src_dir=`echo $1 | sed 's/^\(.*\)\/.*$/\1/'`
        local dst_dir=`echo $src_dir | sed 's/^\/home\/[a-zA-Z0-9_]*\/\?\(.*\)/\/home\/\1/' | sed 's/^\///'`
        local file=`echo $1 | sed 's/^.*\///'`
        mkdir -p $dst_dir
        cp -p "$src_dir/$file" "$dst_dir"
    fi
}

[[ ! -f ~/.config/Xresources/i3  ]] && cp .config/Xresources/i3.example  ~/.config/Xresources/i3

#
# $HOME directory
#
for item in ${home_backup[@]}; do
    if [ -d $item ]; then
        cp -rf $item ~/
    else
        cp $item ~/
    fi
done

#
# .config directory
#
shopt -s extglob
for item in ${direct_backup_configs[@]}; do
    if [[ -d ".config/$item" ]]; then
        cp -p -rf .config/$item ~/.config
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
sudo ln -s ~/.local/lib/bash/vim-tmux-i3-integration /usr/local/bin

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
if [ -d ~/code/sxiv ]; then
    cp -rf apps/sxiv ~/code
fi

sudo cp apps/sxiv/sxiv `which sxiv`
