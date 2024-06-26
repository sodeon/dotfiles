#!/usr/bin/bash -ue
# https://www.oreilly.com/library/view/linux-multimedia-hacks/0596100760/ch01s03.html

# if [[ -z ${1-""} ]]; then
#     echo "Error: src_image_directory not provided."
#     echo ""
#     echo "Usage: $0 src_img_directory"
#     exit 1
# fi

FOLDER="." # path to image folder
SRC_TYPE=bmp
DST_TYPE=png

find ${FOLDER} -iname "*.$SRC_TYPE" -exec mogrify \{} -verbose -format $DST_TYPE \{} \;
# mogrify -format $DST_TYPE *.$SRC_TYPE

# Backup original files
# mkdir -p ./original
# mv *.$SRC_TYPE ./original

# Remove original files
rm *.$SRC_TYPE
