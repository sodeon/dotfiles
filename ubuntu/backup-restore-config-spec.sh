#!/bin/bash
# Resolution and screen size dependent config files:
#   .Xresources
#   .config/rofi/config
#   .config/rofi/arc-dark-workspace-switcher.rasi
#   .config/dunst/dunstrc

wipe_then_backup_list=(
    bin
    .local/lib/bash
    .urxvt/ext
)

backup_list=(
    .bash_aliases
    .tmux.conf
    .vimrc
    .gvimrc
    .zshrc
    .profile
    # .Xmodmap
    .Xresources-cpp
    # .xbindkeysrc
    .lesskey
    # .imwheelrc

    .local/share/applications
    .oh-my-zsh/{themes/andy.zsh-theme,plugins/sd/sd.plugin.zsh}

    .config/keyd
    .config/picom.conf
    .config/htop
    .config/dunst
    .config/rofi
    .config/ranger
    .config/zathura
    # .config/Xmodmap/{keyboard,keyboard-mouse}
    # .config/xbindkeys
    # .config/input-remapper
    .config/i3/{keyboard,mouse,config.hotkeys,gen-config.hotkeys.sh,layouts}
    .config/mpv/{scripts,shaders}
    .config/sxiv
    .config/mcomix
    .config/systemd/user
    .config/hardware/macs
    # .config/hardware

    .config/broot/conf.hjson
    .config/mpv/input.conf
    .config/cmus/rc
    # .config/cmus/{autosave,rc}
    .config/Code/User/{settings.json,keybindings.json}
    .config/MangoHud/MangoHud.conf

    # examples
    .config/autohotkeyrc.example
    .config/dotfiles/dotfilesrc.example
    .config/i3/{config,config.hotkeys,i3blocks.conf.example}
    .config/Xresources/i3.example
)

# Files and directories to backup with machine name as file name suffix.
machine_suffix_backup_list=(
    .config/profile_vars
    .config/autohotkeyrc
    .config/record-screen.rc
    .config/mpv/mpv.conf
    .config/i3/{i3blocks.conf}
    .config/dotfiles/dotfilesrc
    .config/Xresources/{profile,i3,i3.24g2w1g4,i3.ew3270u}
    # ".config/Xresources/!(*.example)" # Bad practice. This only allows machine dependent files in Xresources directory.
)
