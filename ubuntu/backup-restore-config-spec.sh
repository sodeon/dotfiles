#!/bin/bash
# NOTE: This script is not intended to be executed directly. It is sourced by backup.sh/restore.sh

# Files and directories to backup without file name modifications.
# Support brace expansion and extglob.
declare -a direct_backup_configs=(
    htop
    dunst
    rofi
    ranger
    zathura

    mpv/input.conf
    cmus/{autosave,rc}
    Code/User/{settings.json,keybindings.json}

    i3/{config,i3blocks.conf.example,layouts}
    dotfiles/*.example
    hardware/*.example
    Xresources/*.example
)

# Files and directories to backup with machine name as file name suffix.
# Support brace expansion and extglob.
declare -a adding_machine_name_backup_configs=(
    mpv/mpv.conf
    i3/i3blocks.conf
    "dotfiles/!(*.example)"
    "hardware/!(*.example)"
    "Xresources/!(*.example)"
)
