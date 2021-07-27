#!/bin/bash -ue
cd "$(dirname "$(realpath "$0")")"
. backup-restore-config-spec.sh

#------------------------------------------------------------------------------
# Support library
#------------------------------------------------------------------------------
restore-p() {
    # shopt -s extglob
    if [ -d $1 ]; then
        local src_dir=$1
        local dst_dir=$HOME/$1
        # echo d $src_dir $dst_dir
        # # rm -rf "$dst_dir"
        mkdir -p $dst_dir
        cp -p -rf "$src_dir"/* "$dst_dir"
    elif [ -f $1 ]; then
        local src_dir=`echo ./$1 | sed 's/^\(.*\)\/.*$/\1/'`
        local dst_dir="$HOME/$src_dir"
        local file=`echo $1 | sed 's/^.*\///'`
        # echo f $src_dir $dst_dir $file
        mkdir -p $dst_dir
        cp -p "$src_dir/$file" "$dst_dir"
    fi
    # shopt -u extglob
}


#------------------------------------------------------------------------------
# Restore core
#------------------------------------------------------------------------------
[[ ! -f ~/.config/Xresources/i3     ]] && cp .config/Xresources/i3.example  ~/.config/Xresources/i3
[[ ! -f ~/.config/i3/config.monitor ]] && cp .config/i3/config.monitor.pc   ~/.config/i3/config.monitor

for item in ${wipe_then_backup_list[@]}; do
    rm -rf "$HOME/$item"
    restore-p "$item"
done

for item in ${backup_list[@]}; do
    restore-p "$item"
done

if [[ ! -z ${1-} ]]; then
    for item in ${machine_suffix_backup_list[@]}; do
        # shopt -s extglob
        # echo "$item" "$item.$1"
        cp -rf "$item.$1" "$HOME/$item"
        # shopt -u extglob
    done
fi

#
# Self built binaries
#
sudo mkdir -p /usr/lib/x86_64-linux-gnu/rofi
sudo cp -rf ./apps/rofi-plugins/* /usr/lib/x86_64-linux-gnu/rofi
sudo mkdir -p /usr/share/rofi-emoji/
sudo cp ./apps/rofi-plugins/emoji-test.txt /usr/share/rofi-emoji/
