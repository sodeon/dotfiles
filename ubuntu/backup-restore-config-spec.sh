#!/bin/bash
# NOTE: This script is not intended to be executed directly. It is sourced by backup.sh/restore.sh

# Files to backup (no directory) at home directory root
declare -a home_backup_files=(
    .bash_aliases
    .tmux.conf
    .vimrc
    .gvimrc
    .zshrc
    .profile
    .Xmodmap
    .Xresources
    .xbindkeysrc
    .lesskey
    # .imwheelrc
)

# Files and directories to backup without file name modifications.
# Support brace expansion and extglob.
declare -a direct_backup_configs=(
    htop
    dunst
    rofi
    ranger
    zathura
    Xmodmap
    xbindkeys
    mpv/scripts
    sxiv

    mpv/input.conf
    cmus/{autosave,rc}
    Code/User/{settings.json,keybindings.json}

    i3/{config,i3blocks.conf.example,layouts}
    dotfiles/*.example
    Xresources/*.example
)

# Files and directories to backup with machine name as file name suffix.
# Support brace expansion and extglob.
declare -a adding_machine_name_backup_configs=(
    autohotkeyrc
    record-screen.rc
    mpv/mpv.conf
    i3/i3blocks.conf
    "dotfiles/!(*.example)"
    "Xresources/!(*.example)"
)
