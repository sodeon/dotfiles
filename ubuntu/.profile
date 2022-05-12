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

[ -f ~/.config/profile_vars ] && source ~/.config/profile_vars

# NOTE: xrdb loads in
# 1. /etc/X11/xinit/xinitrc -> /etc/X11/Xsession -> /etc/X11/Xsession.d/30x11-common_xresources -> line 18
# 2. GDM:  /etc/gdm3/Xsession
# 3. XFCE: /etc/xdg/xfce4/xinitrc
# Both GDM and XFCE xrdb commands does not support C++ extensions (#define, #include, and etc)
xrdb -merge $HOME/.Xresources-cpp

[[ $XDG_CURRENT_DESKTOP == "i3" ]] && source set-display-monitor # For other desktop environment, use its built-in mechanism

# urxvt daemon
# urxvtd -q -o -f

# play-with-mpv &
if [ -e /home/andy/.nix-profile/etc/profile.d/nix.sh ]; then . /home/andy/.nix-profile/etc/profile.d/nix.sh; fi # added by Nix installer
