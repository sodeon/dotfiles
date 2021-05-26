#!/bin/bash -ue
cd "$(dirname "$(realpath "$0")")"
. backup-restore-config-spec.sh

#
# Create directory and links that will be used later
# Don't put it in provision.sh. This creates dependency on provision.sh and cannot use restore.sh alone
#
set +e
mkdir -p ~/.config/{dotfiles,hardware,Xresources,htop,dunst,rofi,ranger,zathura,xbindkeys,mpv/scripts,sxiv,broot,cmus,Code/User,i3/layouts,Xmodmap,systemd/user,MangoHud}
set -e

# $HOME/.Xresources will source ~/.config/Xresources/{dpi,i3}. If these files does not exist, ~/.profile will fail executing xrdb command
[[ ! -f ~/.config/Xresources/dpi ]] && cp .config/Xresources/dpi.example ~/.config/Xresources/dpi
[[ ! -f ~/.config/Xresources/i3  ]] && cp .config/Xresources/i3.example  ~/.config/Xresources/i3

#
# $HOME directory
#
for item in ${home_backup_files[@]}; do
    cp $item ~/
done

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
