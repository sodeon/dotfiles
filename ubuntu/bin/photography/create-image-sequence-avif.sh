#!/bin/bash -ue

fps=2 #1.5
input_folder="./"
output_file="./out.avif"

if [[ $# -le 1 ]]; then
    echo "Usage: ${0##*/} <input folder> <output file> <fps=$fps>"
    echo
    echo "Create animated (image sequence) AVIF from a folder containing seperate images"
    echo
    exit 1
fi

[[ $# -ge 1 ]] && var="$1" && shift && input_folder="$var"
echo $input_folder
# exit 0;
[[ $# -ge 1 ]] && var="$1" && shift && output_file="$var"
[[ $# -ge 1 ]] && var="$1" && shift && fps="$var"

for fmt in jpg png; do
    # ffmpeg \
    #     -framerate $fps \
    #     -an -loop 0 \
    #     -pattern_type glob -i "*.$fmt" \
    #     -c:v libx264 -pix_fmt yuv420p \
    #     $output_file \
    # && break || true
    # iOS needs HEVC video tag as hvc1
    ffmpeg \
        -framerate $fps \
        -an -loop 0 \
        -pattern_type glob -i "$input_folder/*.$fmt" \
        -c:v libx265 -crf 35 -pix_fmt yuv420p -preset slower -x265-params profile=main -tag:v hvc1 -vf "colormatrix=bt601:bt709" \
        $output_file \
    && break || true
    # ffmpeg \
    #     -framerate $fps \
    #     -an -loop 0 \
    #     -pattern_type glob -i "*.$fmt" \
    #     -c:v libaom-av1 \
    #     $output_file \
    # && break || true
done
