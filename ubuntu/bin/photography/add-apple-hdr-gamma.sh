#!/bin/bash -u

# https://www.exiftool.org/config.html
# https://github.com/anteo/edit-hdr-gamma
# https://discussions.apple.com/docs/DOC-250002653
# hdr gain map? https://gist.github.com/kiding/fa4876ab4ddc797e3f18c71b3c2eeb3a?permalink_comment_id=4289203
#               https://developer.apple.com/forums/thread/709331
# Create lightroom plugin to automate? http://regex.info/blog/2016-09-15/2731

gamma=1.5

if [[ $# -lt 1 ]]; then
    echo "Usage: ${0##*/} <input_file> <gamma=1.5>"
    echo
    echo "Insert Apple Hidden iOS HDR Photo Gamma Hint"
    echo
    exit 1
fi

[[ $# -gt 0 ]] && var="$1" && shift && input_file="$var"
[[ $# -gt 0 ]] && var="$1" && shift && gamma="$var"

printf "\x41\x70\x70\x6c\x65\x20\x69\x4f\x53\x00\x00\x01\x4d\x4d\x00\x01\x00\x21\x00\x0a\x00\x00\x00\x01\x00\x00\x00\x1c\x00\x00\x00\x03\x00\x00\x00\x01" > /tmp/makernotes

exiftool -config ~/.config/exiftool.config -overwrite_original -if 'not $apple:all' "-makernotes<=/tmp/makernotes" "$input_file"
exiftool -config ~/.config/exiftool.config -overwrite_original "-apple:HDRGamma=$gamma" "$input_file"
# exiftool -overwrite_original_in_place -preserve '-CustomRendered=HDR (no original saved)' "$input_file"

# exiftool -overwrite_original_in_place -preserve '-CustomRendered=HDR (no original saved)' "$input_file"
# exiftool -overwrite_original_in_place -preserve '-CustomRendered=HDR' "$input_file"
# exiftool -overwrite_original_in_place -preserve "-CustomRendered=2" "$input_file"
# exiftool -overwrite_original "-CustomRendered=2" "$input_file"
