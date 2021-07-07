#!/usr/bin/bash -ue
cd "$(dirname "$(realpath "$0")")"
. backup-restore-config-spec.sh

#
# $HOME directory
#
for item in ${home_backup_files[@]}; do
    cp -p ~/$item .
done

#
# .config directory
#
shopt -s extglob
for item in ${direct_backup_configs[@]}; do
    if [[ -d "~/.config/$item" ]]; then
        cp -p -rf ~/.config/$item .config/$item/..
    else
        items=(~/.config/$item)
        for sub_item in ${items[@]}; do
            dst=`echo $sub_item | sed -r "s/\/home\/$USER\///"`
            if [[ -d "$sub_item" ]]; then
                mkdir -p $dst
                cp -p -rf $sub_item/* $dst
            else
                cp -p $sub_item $dst
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
                    cp -p $sub_item `echo $sub_item | sed -r "s/\/home\/$USER\///"`.$1
                fi
            done
        fi
    done
fi
shopt -u extglob

#
# Other non-standard config directory
#
mkdir -p .urxvt/ext && cp -p -rf ~/.urxvt/ext .urxvt
cp -p ~/.oh-my-zsh/themes/andy.zsh-theme .oh-my-zsh/themes

#
# .local directory
#
rm -rf .local/lib/bash
cp -p -rf ~/.local/lib/bash .local/lib

shopt -s extglob
cp -p -rf ~/.local/share/applications/!(wine*).desktop .local/share/applications
shopt -u extglob
rm .local/share/applications/thann.play-with-mpv.desktop

#
# bin directory
#
rm -rf ./bin/*
cp -p -rf ~/bin .

#
# Built binaries
#
if [ -d ~/code/sxiv ]; then
	cp -p ~/code/sxiv/sxiv     apps/sxiv
	cp -p ~/code/sxiv/config.h apps/sxiv
	cp -p ~/code/sxiv/sxiv.1   apps/sxiv
	cp -p ~/code/sxiv/exec/*   apps/sxiv/exec
fi

#
# VSCode extensions
#
which code >/dev/null && code --list-extensions > vscode-extensions.list
