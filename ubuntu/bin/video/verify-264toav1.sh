#!/usr/bin/env bash
set -uo pipefail

ORIG_ROOT="$(pwd)/_orig"
CUSTOM_OUT_DIR=""
LOG_DIR="$(pwd)/_log"
VERIFY_LOG="${LOG_DIR}/verify_av1_results.txt"
LOW_QUALITY_LOG="${LOG_DIR}/low_quality_av1.txt"

ENABLE_LOG=0
ENABLE_LOW_QUALITY_LOG=0

usage() {
    echo "Usage: ${0##*/} [-l|--log] [-q|--log-low-quality] [-o|--output <dir>] [file1.mp4 | folder ...]"
    echo
    echo "Options:"
    echo "  -o, --output <dir>     Verify files converted with '264toav1.sh -o <dir>' (custom output directory)"
    echo "  -l, --log              Append verification results to ./_log/verify_av1_results.txt"
    echo "  -q, --log-low-quality  Append files with PSNR < 38 dB to ./_log/low_quality_av1.txt"
    echo "  -h, --help             Show this help message"
    exit 0
}

# Parse command-line switches
targets=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        -o|--output)
            if [[ -z "${2-}" ]]; then
                echo "Error: '$1' requires a directory path argument." >&2
                usage
            fi
            CUSTOM_OUT_DIR="$2"
            shift 2
            ;;
        --output=*)
            CUSTOM_OUT_DIR="${1#*=}"
            shift
            ;;
        -l|--log)
            ENABLE_LOG=1
            shift
            ;;
        -q|--log-low-quality)
            ENABLE_LOW_QUALITY_LOG=1
            shift
            ;;
        -h|--help)
            usage
            ;;
        --)
            shift
            targets+=("$@")
            break
            ;;
        -[lqho]*)
            flags="${1#-}"
            for (( i=0; i<${#flags}; i++ )); do
                ch="${flags:$i:1}"
                case "$ch" in
                    l) ENABLE_LOG=1 ;;
                    q) ENABLE_LOW_QUALITY_LOG=1 ;;
                    h) usage ;;
                    o)
                        if [ $(( i + 1 )) -lt ${#flags} ]; then
                            CUSTOM_OUT_DIR="${flags:$((i+1))}"
                            break
                        elif [[ -n "${2-}" ]]; then
                            CUSTOM_OUT_DIR="$2"
                            shift
                        else
                            echo "Error: '-o' requires a directory path argument." >&2
                            usage
                        fi
                        ;;
                    *) echo "Error: Unknown option '-$ch'" >&2; usage ;;
                esac
            done
            shift
            ;;
        -*)
            echo "Error: Unknown option '$1'" >&2
            usage
            ;;
        *)
            targets+=("$1")
            shift
            ;;
    esac
done

if [ "${#targets[@]}" -eq 0 ]; then
    targets=(".")
fi

if [ -n "$CUSTOM_OUT_DIR" ]; then
    if [ ! -d "$CUSTOM_OUT_DIR" ]; then
        echo "Error: Custom output directory '$CUSTOM_OUT_DIR' does not exist." >&2
        exit 1
    fi
    CUSTOM_OUT_DIR=$(realpath "$CUSTOM_OUT_DIR")
fi

if [ "$ENABLE_LOG" -eq 1 ] || [ "$ENABLE_LOW_QUALITY_LOG" -eq 1 ]; then
    mkdir -p "$LOG_DIR"
fi

if [ "$ENABLE_LOG" -eq 1 ]; then
    {
        echo "===================================================================="
        echo "AV1 Verify Session Started: $(date '+%Y-%m-%d %H:%M:%S') (Output Mode: ${CUSTOM_OUT_DIR:-In-Place})"
        echo "===================================================================="
    } >> "$VERIFY_LOG"
    exec > >(tee -a "$VERIFY_LOG") 2>&1
fi

filters_help=$(ffmpeg -hide_banner -filters 2>/dev/null || true)
if grep -q "scale_cuda" <<< "$filters_help"; then
    has_scale_cuda=1
else
    has_scale_cuda=0
fi

# Optimized SSIM/PSNR runner:
# 1. Uses '-to $end_ts' on inputs so NVDEC halts immediately after the sample window instead of over-decoding.
# 2. Converts to 8-bit planar 'yuv420p' on the GPU via scale_cuda BEFORE hwdownload:
#    - Cuts PCIe transfer volume by 50% (1.5 B/px vs 3.0 B/px for p010le)
#    - Eliminates the single-threaded CPU swscale unpack (p010le -> yuv420p10le)
#    - Unlocks 8-bit AVX2/AVX-512 SIMD in FFmpeg's ssim/psnr filters (~3.5x faster than 16-bit integer path)
run_ssim_psnr() {
    local enc="$1"
    local orig="$2"
    local pre_ts="$3"
    local ts="$4"
    local end_ts="$5"
    local r_fps="$6"
    local shift_enc="${7:-0}"
    local shift_orig="${8:-0}"
    local use_fps_filter="${9:-0}"
    local sample_len=$(( end_ts - ts ))
    [ "$sample_len" -lt 1 ] && sample_len=1

    local sync_chain="trim=start=${ts}:end=${end_ts},setpts=PTS-STARTPTS,trim=start_frame=${shift_enc},setpts=N/TB"
    local sync_chain_ref="trim=start=${ts}:end=${end_ts},setpts=PTS-STARTPTS,trim=start_frame=${shift_orig},setpts=N/TB"

    if [ "$use_fps_filter" -eq 1 ]; then
        sync_chain="fps=${r_fps},trim=start=${ts}:end=${end_ts},setpts=PTS-STARTPTS,trim=start_frame=${shift_enc},setpts=PTS-STARTPTS"
        sync_chain_ref="fps=${r_fps},trim=start=${ts}:end=${end_ts},setpts=PTS-STARTPTS,trim=start_frame=${shift_orig},setpts=PTS-STARTPTS"
    fi

    local out=""

    # Tier 1: GPU NVDEC + GPU scale_cuda (to yuv420p in VRAM) + hard '-to' decode ceiling
    if [ "$has_scale_cuda" -eq 1 ]; then
        out=$(ffmpeg -nostdin -hide_banner -copyts -noautorotate \
            -filter_threads 8 -filter_complex_threads 8 \
            -threads 2 -hwaccel cuda -hwaccel_output_format cuda -extra_hw_frames 8 -ss "$pre_ts" -to "$end_ts" -i "$enc" \
            -threads 2 -hwaccel cuda -hwaccel_output_format cuda -extra_hw_frames 8 -ss "$pre_ts" -to "$end_ts" -i "$orig" \
            -lavfi "[0:v]scale_cuda=format=yuv420p:passthrough=0,hwdownload,format=yuv420p,crop=trunc(iw/2)*2:trunc(ih/2)*2:0:0,${sync_chain},split=2[dist1][dist2]; \
                    [1:v]scale_cuda=format=yuv420p:passthrough=0,hwdownload,format=yuv420p,crop=trunc(iw/2)*2:trunc(ih/2)*2:0:0,${sync_chain_ref},split=2[ref1][ref2]; \
                    [dist1][ref1]ssim; \
                    [dist2][ref2]psnr" \
            -f null - 2>&1 || true)
    fi

    # Tier 2: Fast GPU NVDEC -> direct RAM transfer (no scale_cuda needed) + 8-bit SIMD evaluation
    if ! grep -q "PSNR" <<< "$out"; then
        out=$(ffmpeg -nostdin -hide_banner -copyts -noautorotate \
            -filter_threads 8 -filter_complex_threads 8 \
            -threads 4 -hwaccel cuda -ss "$pre_ts" -to "$end_ts" -i "$enc" \
            -threads 4 -hwaccel cuda -ss "$pre_ts" -to "$end_ts" -i "$orig" \
            -lavfi "[0:v]crop=trunc(iw/2)*2:trunc(ih/2)*2:0:0,${sync_chain},format=yuv420p,split=2[dist1][dist2]; \
                    [1:v]crop=trunc(iw/2)*2:trunc(ih/2)*2:0:0,${sync_chain_ref},format=yuv420p,split=2[ref1][ref2]; \
                    [dist1][ref1]ssim; \
                    [dist2][ref2]psnr" \
            -f null - 2>&1 || true)
    fi

    # Tier 3: CPU decode with -copyts exact timestamp window (if NVDEC rejected stream)
    if ! grep -q "PSNR" <<< "$out"; then
        out=$(ffmpeg -nostdin -hide_banner -copyts -noautorotate \
            -filter_threads 8 -filter_complex_threads 8 \
            -threads 6 -ss "$pre_ts" -to "$end_ts" -i "$enc" \
            -threads 6 -ss "$pre_ts" -to "$end_ts" -i "$orig" \
            -lavfi "[0:v]crop=trunc(iw/2)*2:trunc(ih/2)*2:0:0,${sync_chain},format=yuv420p,split=2[dist1][dist2]; \
                    [1:v]crop=trunc(iw/2)*2:trunc(ih/2)*2:0:0,${sync_chain_ref},format=yuv420p,split=2[ref1][ref2]; \
                    [dist1][ref1]ssim; \
                    [dist2][ref2]psnr" \
            -f null - 2>&1 || true)
    fi

    # Tier 4: Relative seek fallback (if container has non-zero start_time / shifted PTS from camera splice)
    if ! grep -q "PSNR" <<< "$out"; then
        local rel_offset=$(( ts - pre_ts ))
        local rel_end=$(( rel_offset + sample_len ))
        out=$(ffmpeg -nostdin -hide_banner -noautorotate \
            -filter_threads 8 -filter_complex_threads 8 \
            -threads 6 -ss "$pre_ts" -t "$rel_end" -i "$enc" \
            -threads 6 -ss "$pre_ts" -t "$rel_end" -i "$orig" \
            -lavfi "[0:v]crop=trunc(iw/2)*2:trunc(ih/2)*2:0:0,trim=start=${rel_offset}:duration=${sample_len},setpts=PTS-STARTPTS,trim=start_frame=${shift_enc},setpts=N/TB,format=yuv420p,split=2[dist1][dist2]; \
                    [1:v]crop=trunc(iw/2)*2:trunc(ih/2)*2:0:0,trim=start=${rel_offset}:duration=${sample_len},setpts=PTS-STARTPTS,trim=start_frame=${shift_orig},setpts=N/TB,format=yuv420p,split=2[ref1][ref2]; \
                    [dist1][ref1]ssim; \
                    [dist2][ref2]psnr" \
            -f null - 2>&1 || true)
    fi

    echo "$out"
}

evaluate_sample() {
    local enc="$1"
    local orig="$2"
    local ts="$3"
    local sample_len="$4"
    local r_fps="$5"

    # Reduced pre-roll seek from 4s to 2s to cut wasted pre-trim decoding in half
    local pre_ts=$(( ts > 2 ? ts - 2 : 0 ))
    local end_ts=$(( ts + sample_len ))

    local h=$(( ts / 3600 ))
    local m=$(( (ts % 3600) / 60 ))
    local s=$(( ts % 60 ))
    local time_str
    time_str=$(printf "%02d:%02d:%02d" "$h" "$m" "$s")

    local metric_out ssim_line ssim_val ssim_db psnr_avg psnr_int note=""
    metric_out=$(run_ssim_psnr "$enc" "$orig" "$pre_ts" "$ts" "$end_ts" "$r_fps" 0 0 0)

    ssim_line=$(grep "SSIM" <<< "$metric_out" | tail -n 1 || true)
    ssim_val=$(grep -oP "All:\K[0-9.]+" <<< "$ssim_line" || true)
    ssim_db=$(grep -oP "All:[0-9.]+ \(\K[0-9.]+" <<< "$ssim_line" || true)
    psnr_avg=$(grep -oP "PSNR .* average:\K([0-9.]+|inf)" <<< "$metric_out" | tail -n 1 || true)
    psnr_int="${psnr_avg%.*}"

    # 1) If PSNR < 38 dB, test +-1, +-2, +-3 frame shifts with 1-to-1 frame lock (setpts=N/TB)
    if [[ -n "$psnr_int" && "$psnr_int" =~ ^[0-9]+$ ]] && [ "$psnr_int" -lt 38 ]; then
        for offset_pair in "1:0" "0:1" "2:0" "0:2" "3:0" "0:3"; do
            local se=${offset_pair%:*}
            local so=${offset_pair#*:}
            local retry_out retry_psnr retry_int
            retry_out=$(run_ssim_psnr "$enc" "$orig" "$pre_ts" "$ts" "$end_ts" "$r_fps" "$se" "$so" 0)
            retry_psnr=$(grep -oP "PSNR .* average:\K([0-9.]+|inf)" <<< "$retry_out" | tail -n 1 || true)
            retry_int="${retry_psnr%.*}"

            if [[ -n "$retry_int" && "$retry_int" =~ ^[0-9]+$ ]] && [ "$retry_int" -gt "$psnr_int" ]; then
                psnr_int="$retry_int"
                psnr_avg="$retry_psnr"
                ssim_line=$(grep "SSIM" <<< "$retry_out" | tail -n 1 || true)
                ssim_val=$(grep -oP "All:\K[0-9.]+" <<< "$ssim_line" || true)
                ssim_db=$(grep -oP "All:[0-9.]+ \(\K[0-9.]+" <<< "$ssim_line" || true)
                note=" [Aligned +${se}/-${so} frame]"
                [ "$psnr_int" -ge 38 ] && break
            fi
        done
    fi

    # 2) If still < 38 dB (e.g., extreme VFR stream where CFR resampling helps), try fps=${r_fps} mode
    if [[ -n "$psnr_int" && "$psnr_int" =~ ^[0-9]+$ ]] && [ "$psnr_int" -lt 38 ]; then
        for offset_pair in "0:0" "1:0" "0:1"; do
            local se=${offset_pair%:*}
            local so=${offset_pair#*:}
            local retry_out retry_psnr retry_int
            retry_out=$(run_ssim_psnr "$enc" "$orig" "$pre_ts" "$ts" "$end_ts" "$r_fps" "$se" "$so" 1)
            retry_psnr=$(grep -oP "PSNR .* average:\K([0-9.]+|inf)" <<< "$retry_out" | tail -n 1 || true)
            retry_int="${retry_psnr%.*}"

            if [[ -n "$retry_int" && "$retry_int" =~ ^[0-9]+$ ]] && [ "$retry_int" -gt "$psnr_int" ]; then
                psnr_int="$retry_int"
                psnr_avg="$retry_psnr"
                ssim_line=$(grep "SSIM" <<< "$retry_out" | tail -n 1 || true)
                ssim_val=$(grep -oP "All:\K[0-9.]+" <<< "$ssim_line" || true)
                ssim_db=$(grep -oP "All:[0-9.]+ \(\K[0-9.]+" <<< "$ssim_line" || true)
                if [ "$offset_pair" = "0:0" ]; then
                    note=" [CFR-Synced]"
                else
                    note=" [CFR-Synced +${se}/-${so} frame]"
                fi
                [ "$psnr_int" -ge 38 ] && break
            fi
        done
    fi

    echo "Sample @ ${time_str} (${sample_len}s) -> SSIM: ${ssim_val:-N/A} (${ssim_db:-N/A} dB) | PSNR: ${psnr_avg:-N/A} dB${note}"
}

resolve_pair() {
    local input_path="$1"
    local abs_path
    abs_path=$(realpath "$input_path")

    ENC_FILE=""
    ORIG_FILE=""
    DISPLAY_REL=""
    ORIG_LABEL=""
    ENC_LABEL=""

    # Mode A: Custom Output Directory (-o / --output <dir>)
    if [ -n "$CUSTOM_OUT_DIR" ]; then
        if [[ "$abs_path" == "$CUSTOM_OUT_DIR"/* ]]; then
            ENC_FILE="$abs_path"
            local rel="${abs_path#"${CUSTOM_OUT_DIR}"/}"
            DISPLAY_REL="$rel"
            if [[ "$rel" == external/* ]]; then
                ORIG_FILE="/${rel#external/}"
            else
                ORIG_FILE="$(pwd)/${rel}"
            fi
        else
            ORIG_FILE="$abs_path"
            local rel_cwd
            rel_cwd=$(realpath --relative-to="$(pwd)" "$abs_path")
            DISPLAY_REL="$rel_cwd"
            local sub_rel="$rel_cwd"
            if [[ "$rel_cwd" == ..* ]]; then
                sub_rel="external/${abs_path#/}"
            fi
            ENC_FILE="${CUSTOM_OUT_DIR}/${sub_rel}"
        fi
        ENC_LABEL="Converted (Output)  : $ENC_FILE"
        ORIG_LABEL="Original  (Source)  : $DISPLAY_REL"
        return
    fi

    # Mode B: In-Place Replacement with _orig/ or orig/ backup
    if [[ "$abs_path" == */_orig/* ]]; then
        ORIG_FILE="$abs_path"
        local prefix="${abs_path%%/_orig/*}"
        local rel="${abs_path#*/_orig/}"
        DISPLAY_REL="$rel"
        if [[ "$rel" == external/* ]]; then
            ENC_FILE="/${rel#external/}"
        else
            ENC_FILE="${prefix}/${rel}"
        fi
        ENC_LABEL="Converted (In-Place): $DISPLAY_REL"
        ORIG_LABEL="Original  (Backup)  : _orig/$DISPLAY_REL"
        return
    elif [[ "$abs_path" == */orig/* ]]; then
        ORIG_FILE="$abs_path"
        local prefix="${abs_path%%/orig/*}"
        local rel="${abs_path#*/orig/}"
        DISPLAY_REL="$rel"
        if [[ "$rel" == external/* ]]; then
            ENC_FILE="/${rel#external/}"
        else
            ENC_FILE="${prefix}/${rel}"
        fi
        ENC_LABEL="Converted (In-Place): $DISPLAY_REL"
        ORIG_LABEL="Original  (Backup)  : orig/$DISPLAY_REL"
        return
    fi

    local rel_cwd
    rel_cwd=$(realpath --relative-to="$(pwd)" "$abs_path")
    local sub_rel="$rel_cwd"
    if [[ "$rel_cwd" == ..* ]]; then
        sub_rel="external/${abs_path#/}"
    fi
    if [ -f "${ORIG_ROOT}/${sub_rel}" ]; then
        ENC_FILE="$abs_path"
        ORIG_FILE="${ORIG_ROOT}/${sub_rel}"
        DISPLAY_REL="$rel_cwd"
        ENC_LABEL="Converted (In-Place): $DISPLAY_REL"
        ORIG_LABEL="Original  (Backup)  : _orig/$sub_rel"
        return
    fi

    local search_dir
    search_dir=$(dirname "$abs_path")
    while [ "$search_dir" != "/" ]; do
        for bdir in "_orig" "orig"; do
            if [ -d "${search_dir}/${bdir}" ]; then
                local rel_from_parent
                rel_from_parent=$(realpath --relative-to="$search_dir" "$abs_path")
                if [ -f "${search_dir}/${bdir}/${rel_from_parent}" ]; then
                    ENC_FILE="$abs_path"
                    ORIG_FILE="${search_dir}/${bdir}/${rel_from_parent}"
                    DISPLAY_REL="$rel_from_parent"
                    ENC_LABEL="Converted (In-Place): $DISPLAY_REL"
                    ORIG_LABEL="Original  (Backup)  : ${bdir}/$DISPLAY_REL"
                    return
                fi
            fi
        done
        search_dir=$(dirname "$search_dir")
    done
}

verify_file() {
    local f="$1"
    [ ! -f "$f" ] && return

    resolve_pair "$f"

    if [ -z "$ENC_FILE" ] || [ -z "$ORIG_FILE" ] || [ ! -f "$ENC_FILE" ] || [ ! -f "$ORIG_FILE" ]; then
        return
    fi

    local probe_enc enc_codec="" enc_profile=""
    probe_enc=$(ffprobe -v error -select_streams v:0 \
        -show_entries stream=codec_name,profile \
        -of default=noprint_wrappers=1 "$ENC_FILE" 2>/dev/null | tr -d '\r' || true)
    while IFS='=' read -r k v; do
        case "$k" in
            codec_name) [ -z "$enc_codec" ] && enc_codec="$v" ;;
            profile)    [ -z "$enc_profile" ] && enc_profile="$v" ;;
        esac
    done <<< "$probe_enc"

    if [ "${enc_codec:-}" != "av1" ]; then
        echo "Skipping '$DISPLAY_REL': Target file is '${enc_codec:-unknown}' (not yet converted to AV1)."
        return
    fi

    local probe_orig orig_codec="" width=0 height=0 r_fps="" duration_float="" duration=0
    probe_orig=$(ffprobe -v error -select_streams v:0 \
        -show_entries stream=codec_name,width,height,r_frame_rate,duration -show_entries format=duration \
        -of default=noprint_wrappers=1 "$ORIG_FILE" 2>/dev/null | tr -d '\r' || true)
    while IFS='=' read -r k v; do
        case "$k" in
            codec_name)   [ -z "$orig_codec" ] && orig_codec="$v" ;;
            width)        [ "$width" -eq 0 ] && [[ "$v" =~ ^[0-9]+$ ]] && width="$v" ;;
            height)       [ "$height" -eq 0 ] && [[ "$v" =~ ^[0-9]+$ ]] && height="$v" ;;
            r_frame_rate) [ -z "$r_fps" ] && r_fps="$v" ;;
            duration)     [[ "$v" =~ ^[0-9]+(\.[0-9]+)?$ ]] && duration_float="$v" ;;
        esac
    done <<< "$probe_orig"
    duration=${duration_float%.*}

    if [[ ! "${duration:-}" =~ ^[0-9]+$ ]] || [ "$duration" -le 0 ]; then
        duration=60
    fi
    [ -z "$r_fps" ] && r_fps="60000/1001"

    local orig_bytes enc_bytes orig_mb enc_mb savings
    orig_bytes=$(stat -c%s "$ORIG_FILE")
    enc_bytes=$(stat -c%s "$ENC_FILE")
    orig_mb=$(awk "BEGIN {printf \"%.1f\", $orig_bytes / 1048576}")
    enc_mb=$(awk "BEGIN {printf \"%.1f\", $enc_bytes / 1048576}")
    savings=$(awk "BEGIN {printf \"%.1f\", (1 - $enc_bytes / $orig_bytes) * 100}")

    echo "============================================================"
    echo "$ENC_LABEL (${enc_mb} MiB | -${savings}% | AV1 ${enc_profile})"
    echo "$ORIG_LABEL (${orig_mb} MiB | ${orig_codec})"
    echo "Stream Info         : ${width}x${height} @ ${r_fps} fps | Duration: ${duration}s"
    echo "------------------------------------------------------------"

    local sample_len=10
    if [ "$duration" -lt 15 ]; then
        sample_len=$(( duration / 3 ))
        [ "$sample_len" -lt 1 ] && sample_len=1
    elif [ "$duration" -lt 50 ]; then
        sample_len=3
    fi

    local t1=$(( duration * 20 / 100 ))
    local t2=$(( duration * 50 / 100 ))
    local t3=$(( duration * 80 / 100 ))

    if [ $(( t3 + sample_len )) -gt "$duration" ]; then
        t3=$(( duration > sample_len ? duration - sample_len : 0 ))
    fi

    local tmp1 tmp2 tmp3
    tmp1=$(mktemp)
    tmp2=$(mktemp)
    tmp3=$(mktemp)

    evaluate_sample "$ENC_FILE" "$ORIG_FILE" "$t1" "$sample_len" "$r_fps" > "$tmp1" &
    local p1=$!
    evaluate_sample "$ENC_FILE" "$ORIG_FILE" "$t2" "$sample_len" "$r_fps" > "$tmp2" &
    local p2=$!
    evaluate_sample "$ENC_FILE" "$ORIG_FILE" "$t3" "$sample_len" "$r_fps" > "$tmp3" &
    local p3=$!

    wait "$p1" "$p2" "$p3"

    local combined_samples
    combined_samples=$(cat "$tmp1" "$tmp2" "$tmp3")
    echo "$combined_samples"
    rm -f "$tmp1" "$tmp2" "$tmp3"

    if [ "$ENABLE_LOW_QUALITY_LOG" -eq 1 ]; then
        local low_psnr_detected=0
        local min_psnr="999.0"

        while IFS= read -r line; do
            local p_val
            p_val=$(grep -oP "PSNR: \K([0-9.]+|inf|N/A)" <<< "$line" | head -n 1 || true)
            if [ "$p_val" = "N/A" ] || [ -z "$p_val" ]; then
                low_psnr_detected=1
                min_psnr="N/A"
                break
            fi
            if [ "$p_val" = "inf" ]; then
                continue
            fi
            if awk "BEGIN {exit !($p_val < 38.0)}"; then
                low_psnr_detected=1
            fi
            if [ "$min_psnr" != "N/A" ] && awk "BEGIN {exit !($p_val < $min_psnr)}"; then
                min_psnr="$p_val"
            fi
        done <<< "$combined_samples"

        if [ "$low_psnr_detected" -eq 1 ]; then
            if [ ! -f "$LOW_QUALITY_LOG" ] || ! grep -Fxq "${DISPLAY_REL} (Min PSNR: ${min_psnr} dB)" "$LOW_QUALITY_LOG"; then
                echo "${DISPLAY_REL} (Min PSNR: ${min_psnr} dB)" >> "$LOW_QUALITY_LOG"
            fi
            echo "[Flagged] Low PSNR (< 38 dB) logged to: $LOW_QUALITY_LOG"
        fi
    fi

    echo "============================================================"
}

declare -A seen_files=()

for item in "${targets[@]}"; do
    if [ -d "$item" ]; then
        while IFS= read -r -d '' f; do
            resolve_pair "$f"
            if [ -n "$ENC_FILE" ] && [ -f "$ENC_FILE" ] && [ -f "$ORIG_FILE" ] && [ -z "${seen_files[$ENC_FILE]+x}" ]; then
                seen_files["$ENC_FILE"]=1
                verify_file "$f"
            fi
        done < <(find "$item" \
            -path "$ORIG_ROOT" -prune -o \
            -path "$LOG_DIR" -prune -o \
            -type d \( -name "_orig" -o -name "orig" -o -name "_log" \) -prune -o \
            -type f \( -iname "*.mp4" -o -iname "*.mov" \) ! -name ".*.av1_tmp.mp4" ! -name ".*.hevc_tmp.mp4" -print0 | sort -z)
    elif [ -f "$item" ]; then
        resolve_pair "$item"
        if [ -n "$ENC_FILE" ] && [ -f "$ENC_FILE" ] && [ -f "$ORIG_FILE" ] && [ -z "${seen_files[$ENC_FILE]+x}" ]; then
            seen_files["$ENC_FILE"]=1
            verify_file "$item"
        else
            if [ -n "$CUSTOM_OUT_DIR" ]; then
                echo "Skipping '$item': Could not find matching original/converted pair with '$CUSTOM_OUT_DIR'."
            else
                echo "Skipping '$item': Could not find matching backup/converted pair in '_orig/'."
            fi
        fi
    else
        echo "Skipping '$item': Path does not exist."
    fi
done
