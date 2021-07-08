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
[[ ! -f ~/.config/Xresources/i3  ]] && cp .config/Xresources/i3.example  ~/.config/Xresources/i3

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
# if [ ! -d /usr/lib/x86_64-linux-gnu/rofi ]; then
# 	sudo mkdir -p /usr/lib/x86_64-linux-gnu/rofi
# fi
# sudo cp -rf ./apps/rofi-plugins/* /usr/lib/x86_64-linux-gnu/rofi
# if [ ! -d /usr/share/rofi-emoji/ ]; then
# 	sudo mkdir -p /usr/share/rofi-emoji/
# fi
# sudo cp ./apps/rofi-plugins/emoji-test.txt /usr/share/rofi-emoji/
# if [ -d ~/code/sxiv ]; then
#     cp -rf apps/sxiv ~/code
# fi

# sudo cp apps/sxiv/sxiv `which sxiv`
