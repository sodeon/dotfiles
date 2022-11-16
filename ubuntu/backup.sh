#!/usr/bin/bash -ue
cd "$(dirname "$(realpath "$0")")"
. backup-restore-config-spec.sh

#------------------------------------------------------------------------------
# Support library
#------------------------------------------------------------------------------
backup-p() {
    # shopt -s extglob
    if [ -d $1 ]; then
        local src_dir=$1
        local dst_dir=`echo $src_dir | sed 's/^\/home\/[a-zA-Z0-9_]*\/\?\(.*\)/\1/' | sed 's/^\///'` # Stripe $HOME from path
        # echo d $src_dir $dst_dir
        # # rm -rf "$dst_dir"
        mkdir -p $dst_dir
        cp -p -rf "$src_dir"/* "$dst_dir"
    elif [ -f $1 ]; then
        local src_dir=`echo $1 | sed 's/^\(.*\)\/.*$/\1/'`
        local dst_dir=`echo $src_dir | sed 's/^\/home\/[a-zA-Z0-9_]*\/\?\(.*\)/.\/\1/' | sed 's/^\///'` # Stripe $HOME from path
        local file=`echo $1 | sed 's/^.*\///'`
        # echo f $src_dir $dst_dir $file
        mkdir -p $dst_dir
        cp -p "$src_dir/$file" "$dst_dir"
    fi
    # shopt -u extglob
}


#------------------------------------------------------------------------------
# Backup core
#------------------------------------------------------------------------------
for item in ${wipe_then_backup_list[@]}; do
    rm -rf "$item"
    backup-p "$HOME/$item"
done

for item in ${backup_list[@]}; do
    backup-p "$HOME/$item"
done

if [[ ! -z ${1-} ]]; then
    for item in ${machine_suffix_backup_list[@]}; do
        # shopt -s extglob
        if ([ -d "$HOME/$item" ] || [ -f "$HOME/$item" ]); then
            cp -rf "$HOME/$item" "$item.$1"
        fi
        # shopt -u extglob
    done
fi

#
# keyd config
#
cp /etc/systemd/system/keyd.* apps/keyboard-config/keyd

#
# Self built binaries
#
if [ -d ~/code/sxiv ]; then
	cp -p ~/code/sxiv/sxiv     apps/sxiv
	cp -p ~/code/sxiv/config.h apps/sxiv
	cp -p ~/code/sxiv/sxiv.1   apps/sxiv
	cp -p ~/code/sxiv/exec/*   apps/sxiv/exec
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
which code >/dev/null && code --list-extensions > vscode-extensions.list


#
# Discard trivial changes
#
rm -f .local/share/applications/wine-extension-*
rm -f .local/share/applications/mimeinfo.cache

exit 0
