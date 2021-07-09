#!/bin/bash -ue
cd "$(dirname "$(realpath "$0")")"
. backup-restore-config-spec.sh

#
# $HOME directory
#
for item in ${home_backup_files[@]}; do
    cp ~/$item .
done

#
# .config directory
#
shopt -s extglob
for item in ${direct_backup_configs[@]}; do
    if [[ -d "~/.config/$item" ]]; then
        cp -rf ~/.config/$item .config/$item/..
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

shopt -s extglob
cp -rf ~/.local/share/applications/!(wine*).desktop .local/share/applications
shopt -u extglob
# rm .local/share/applications/thann.play-with-mpv.desktop

#
# bin directory
#
rm -rf ./bin/*
cp -rf ~/bin .

#
# Built binaries
#
if [ -d ~/code/sxiv ]; then
	cp ~/code/sxiv/sxiv     apps/sxiv
	cp ~/code/sxiv/config.h apps/sxiv
	cp ~/code/sxiv/sxiv.1   apps/sxiv
	cp ~/code/sxiv/exec/*   apps/sxiv/exec
fi
if [ -d ~/code/panasonic-viera ]; then
	cp     ~/code/panasonic-viera/setup.py             apps/panasonic-viera
	cp     ~/code/panasonic-viera/setup.cfg            apps/panasonic-viera
	cp     ~/code/panasonic-viera/requirements.txt     apps/panasonic-viera
	cp -rf ~/code/panasonic-viera/panasonic_viera/*.py apps/panasonic-viera/panasonic_viera
fi


#
# VSCode extensions
#
which code && code --list-extensions > vscode-extensions.list # Some machines do not install VSCode
