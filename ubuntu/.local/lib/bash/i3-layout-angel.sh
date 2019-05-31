#!/bin/bash

# 多開大天使之劍

if [ ! -z $1 ]; then
	i3-msg "workspace $1" 
fi

layoutFolder="$HOME/.config/i3/layouts"
url="https://m.gm99.com/h5/page/pc?game_id=26"

i3-msg "append_layout $layoutFolder/angel.json;
        exec google-chrome --new-window $url;
        exec google-chrome --new-window $url --user-data-dir=$HOME/.config/google-chrome-cheng1015;
        rename workspace $1 to \"$1: Angel\""
