#!/usr/bin/bash -u
# https://www.oreilly.com/library/view/linux-multimedia-hacks/0596100760/ch01s03.html

# if [[ -z ${1-""} ]]; then
#     echo "Error: src_image_directory not provided."
#     echo ""
#     echo "Usage: $0 src_img_directory"
#     exit 1
# fi

FOLDER="." # path to image folder
DST_TYPE=png

SRC_TYPE=jpg
find ${FOLDER} -iname "*.$SRC_TYPE" -exec mogrify \{} -verbose -format $DST_TYPE \{} \;
rm *.$SRC_TYPE

SRC_TYPE=jpeg
find ${FOLDER} -iname "*.$SRC_TYPE" -exec mogrify \{} -verbose -format $DST_TYPE \{} \;
rm *.$SRC_TYPE
