#!/usr/bin/bash -ue
# Purpose: batch image resizer
# Source: https://guides.wp-bullet.com
# Author: Mike

# Usage: $0 $file_extension

FOLDER="." # path to image folder
WIDTH=2560  # max width
HEIGHT=1440 # max height
TYPE=${1-"bmp"}


size=$WIDTH"x"$HEIGHT

find ${FOLDER} -iname "*.$TYPE" -exec mogrify \{} -verbose -resize $size\> \{} \;
# find ${FOLDER} -iname "*.$TYPE" -exec convert \{} -verbose -resize $size\> \{} \;

# alternative
#mogrify -path ${FOLDER} -resize $size% *.png -verbose
