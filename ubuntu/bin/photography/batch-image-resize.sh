#!/usr/bin/bash -ue
# Purpose: batch image resizer
# Source: https://guides.wp-bullet.com
# Author: Mike

# if [[ -z ${1-""} ]]; then
#     echo "Error: src_image_directory not provided."
#     echo ""
#     echo "Usage: $0 src_img_directory"
#     exit 1
# fi

# FOLDER="$1" # path to image folder
FOLDER="." # path to image folder
WIDTH=1920  # max width
HEIGHT=1080 # max height
TYPE=bmp


size=$WIDTH"x"$HEIGHT

find ${FOLDER} -iname "*.$TYPE" -exec convert \{} -verbose -resize $size\> \{} \;

# alternative
#mogrify -path ${FOLDER} -resize $size% *.png -verbose
