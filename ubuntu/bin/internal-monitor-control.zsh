#!/bin/zsh

if [[ $1 = "b" ]]; then
    light -G | xargs printf '%.*f%%' 0
elif [[ $1 = "bu" ]]; then
    light -A 5
elif [[ $1 = "bd" ]]; then
    light -U 5
elif [[ $1 = "bv" ]]; then
    light -S 25
elif [[ $1 = "br" ]]; then
    light -S 15
elif [[ $1 = "cr" ]]; then
elif [[ $1 = "cv" ]]; then
fi
