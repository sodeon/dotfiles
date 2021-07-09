# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
	. "$HOME/.bashrc"
    fi
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi


#---------------------------------------------------------------------------------------
# Andy
#---------------------------------------------------------------------------------------
# NOTE: When ssh login, .profile won't be executed.
if [ -d "$HOME/.local/lib/bash" ] ; then
    PATH="$HOME/.local/lib/bash:$PATH"
fi

# HiDPI settings
# Only apply theses settings in i3. Gnome has its own dpi scaling method only partially compatible with this one
# TODO: Try to support per-minotor hidpi settings
sed -i -e 's/^Xft.dpi/!&/'      $HOME/.config/Xresources/dpi
sed -i -e 's/^Xcursor.size/!&/' $HOME/.config/Xresources/dpi
sed -i -e 's/^rofi.dpi/!&/'     $HOME/.config/Xresources/dpi
if [[ $XDG_CURRENT_DESKTOP == "i3" ]]; then
    if ([[ -f ~/.config/hardware/external-displayrc ]] && source ~/.config/hardware/external-displayrc && xrandr | grep "\<$interface\> connected" && [[ $is_high_dpi == "true" ]]) || 
       ([[ -f ~/.config/hardware/internal-displayrc ]] && source ~/.config/hardware/internal-displayrc && xrandr | grep "\<$interface\> connected" && [[ $is_high_dpi == "true" ]]); then
        sed -i -e 's/^!Xft.dpi/Xft.dpi/'           $HOME/.config/Xresources/dpi
        sed -i -e 's/^!Xcursor.size/Xcursor.size/' $HOME/.config/Xresources/dpi
        sed -i -e 's/^!rofi.dpi/rofi.dpi/'         $HOME/.config/Xresources/dpi
        export GDK_SCALE=2
        export GDK_DPI_SCALE=0.5
        export QT_AUTO_SCREEN_SET_FACTOR=0
        export QT_SCALE_FACTOR=2
        export QT_FONT_DPI=96
    fi
fi
# NOTE: this duplicate functionalities in /etc/X11/xinit/xinitrc -> /etc/X11/Xsession -> /etc/X11/Xsession.d/30x11-common_xresources -> line 18
xrdb $HOME/.Xresources

# urxvt daemon
urxvtd -q -o -f

[[ $XDG_CURRENT_DESKTOP == "i3" ]] && (set-display-monitor &) # For gnome desktop environment, use gnome's built-in scaling
# play-with-mpv &

# Additional "less" keybindings
# lesskey
if [ -e /home/andy/.nix-profile/etc/profile.d/nix.sh ]; then . /home/andy/.nix-profile/etc/profile.d/nix.sh; fi # added by Nix installer
