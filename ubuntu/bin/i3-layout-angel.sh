#!/bin/bash

# 多開大天使之劍

if [ ! -z $1 ]; then
	i3-msg "workspace $1" 
fi

layoutFolder="~/.config/i3/layout"
url="https://m.gm99.com/h5/page/pc?game_id=26"

i3-msg "append_layout $layoutFolder/angel.json; exec google-chrome --new-window $url; exec firefox $url" 
