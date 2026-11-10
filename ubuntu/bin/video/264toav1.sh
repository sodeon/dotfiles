#!/usr/bin/env bash
set -uo pipefail

# Maximum UI/worker slots (3 slots total)
MAX_JOBS=3
T3B_THREAD_CNT=4
# Weighted concurrency capacity (MAX_WEIGHT=4):
# - FHD weight = 1 -> 3x FHD = 3 <= 4 (3 streams)
# - 4K  weight = 2 -> 2x 4K  = 4 <= 4 (2 streams)
# - Mixed          -> 1x 4K (2) + 2x FHD (1+1) = 4 <= 4 (3 streams)
MAX_WEIGHT=6

# Default toggle for Tier 3 (CPU decode -> GPU NVENC): 0 = disabled (default), 1 = enabled
ENABLE_TIER3=0
# Default toggle for converting HEVC sources: 0 = skip HEVC (only H.264 -> AV1), 1 = allow HEVC -> AV1
ALLOW_HEVC=0

ORIG_ROOT="$(pwd)/_orig"
CUSTOM_OUT_DIR=""
LOG_DIR="$(pwd)/_log"
RESULTS_LOG="${LOG_DIR}/results.txt"
FAILED_LOG="${LOG_DIR}/failed.txt"

ENABLE_LOG=0
SUPPRESS_ERRORS=0

usage() {
    echo "Usage: ${0##*/} [-l|--log] [-s|--suppress-errors] [-3|--tier3] [--no-tier3] [--allow-hevc] [-o|--output <dir>] <.|file1.mp4|*.mp4|folder1 ...>"
    echo
    echo "Options:"
    echo "  -o, --output <dir>     Write converted AV1 files to <dir> instead of replacing in-place (originals untouched)"
    echo "  -l, --log              Write output (info + errors) to ./_log/results.txt"
    echo "  -s, --suppress-errors  Hide errors on terminal while keeping info & multi-line progress bars"
    echo "  -3, --tier3            Enable Tier 3 fallback (CPU decode -> GPU 10-bit AV1 encode)"
    echo "      --no-tier3         Disable Tier 3 fallback (default; logs skipped files to ./_log/failed.txt)"
    echo "      --allow-hevc       Also convert HEVC (H.265) files to AV1 (by default, only H.264 files are converted)"
    echo "  -h, --help             Show this help message"
    exit 1
}

if [ "$#" -eq 0 ]; then
    usage
fi

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
        -s|--suppress-errors)
            SUPPRESS_ERRORS=1
            shift
            ;;
        -3|--tier3)
            ENABLE_TIER3=1
            shift
            ;;
        --no-tier3)
            ENABLE_TIER3=0
            shift
            ;;
        --allow-hevc)
            ALLOW_HEVC=1
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
        -[l3sho]*)
            flags="${1#-}"
            for (( i=0; i<${#flags}; i++ )); do
                ch="${flags:$i:1}"
                case "$ch" in
                    l) ENABLE_LOG=1 ;;
                    s) SUPPRESS_ERRORS=1 ;;
                    3) ENABLE_TIER3=1 ;;
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
    usage
fi

if [ -n "$CUSTOM_OUT_DIR" ]; then
    mkdir -p "$CUSTOM_OUT_DIR"
    CUSTOM_OUT_DIR=$(realpath "$CUSTOM_OUT_DIR")
fi

if [ "$ENABLE_LOG" -eq 1 ]; then
    mkdir -p "$LOG_DIR"
    {
        echo "===================================================================="
        echo "AV1 Session Started: $(date '+%Y-%m-%d %H:%M:%S') (Tier 3: $ENABLE_TIER3 | Output: ${CUSTOM_OUT_DIR:-In-Place})"
        echo "===================================================================="
    } >> "$RESULTS_LOG"
fi

UI_DIR=$(mktemp -d)
UI_FIFO="${UI_DIR}/ui.fifo"
mkfifo "$UI_FIFO"

for (( s=0; s<MAX_JOBS; s++ )); do
    echo "[Slot $((s+1))] Idle" > "${UI_DIR}/slot_${s}.txt"
done

display_manager() {
    local drawn=0

    draw_slots() {
        printf "\033[?7l"
        for (( s=0; s<MAX_JOBS; s++ )); do
            local line=""
            if [ -f "${UI_DIR}/slot_${s}.txt" ]; then
                IFS= read -r line < "${UI_DIR}/slot_${s}.txt" || true
            fi
            [ -z "$line" ] && line="[Slot $((s+1))] Idle"
            printf "\r\033[2K%s\n" "$line"
        done
        printf "\033[?7h"
        drawn=1
    }

    clear_slots() {
        if [ "$drawn" -eq 1 ]; then
            for (( s=0; s<MAX_JOBS; s++ )); do
                printf "\033[1A\r\033[2K"
            done
            drawn=0
        fi
    }

    draw_slots

    while IFS= read -r cmd; do
        case "$cmd" in
            REFRESH)
                clear_slots
                draw_slots
                ;;
            MSG:*)
                clear_slots
                printf "%s\n" "${cmd#MSG:}"
                draw_slots
                ;;
            ERR:*)
                if [ "$SUPPRESS_ERRORS" -eq 0 ]; then
                    clear_slots
                    printf "%s\n" "${cmd#ERR:}" >&2
                    draw_slots
                fi
                ;;
            QUIT)
                clear_slots
                printf "\033[?7h"
                break
                ;;
        esac
    done < "$UI_FIFO"
}

display_manager &
DISPLAY_PID=$!
exec 4>"$UI_FIFO"

ui_info() {
    while IFS= read -r line; do
        printf "MSG:%s\n" "$line" >&4
        if [ "$ENABLE_LOG" -eq 1 ]; then
            printf "%s\n" "$line" >> "$RESULTS_LOG"
        fi
    done <<< "$1"
}

ui_err() {
    while IFS= read -r line; do
        printf "ERR:%s\n" "$line" >&4
        if [ "$ENABLE_LOG" -eq 1 ]; then
            printf "%s\n" "$line" >> "$RESULTS_LOG"
        fi
    done <<< "$1"
}

update_slot_status() {
    local slot="$1"
    local text="$2"
    local tmp_slot="${UI_DIR}/slot_${slot}.tmp"
    local final_slot="${UI_DIR}/slot_${slot}.txt"
    printf "%s\n" "$text" > "$tmp_slot"
    mv -f "$tmp_slot" "$final_slot"
    printf "REFRESH\n" >&4
}

log_failed() {
    local rel="$1"
    mkdir -p "$LOG_DIR"
    if [ ! -f "$FAILED_LOG" ] || ! grep -Fxq "$rel" "$FAILED_LOG"; then
        echo "$rel" >> "$FAILED_LOG"
    fi
}

declare -a slot_pids=()
declare -a slot_tmps=()
declare -a slot_weights=()
for (( s=0; s<MAX_JOBS; s++ )); do
    slot_pids[$s]=""
    slot_tmps[$s]=""
    slot_weights[$s]=0
done

cleanup_and_exit() {
    for pid in "${slot_pids[@]}"; do
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            kill -9 "$pid" 2>/dev/null || true
            wait "$pid" 2>/dev/null || true
        fi
    done
    printf "QUIT\n" >&4 2>/dev/null || true
    exec 4>&- 2>/dev/null || true
    wait "$DISPLAY_PID" 2>/dev/null || true
    printf "\033[?7h"
    rm -rf "$UI_DIR"

    echo -e "\n[Interrupted] Stopped all FFmpeg jobs and cleaned up temp files."
    for tmp_file in "${slot_tmps[@]}"; do
        if [ -n "$tmp_file" ] && [ -e "$tmp_file" ]; then
            rm -f "$tmp_file"
            echo "Removed incomplete temp file: $tmp_file"
        fi
    done
    exit 130
}

trap cleanup_and_exit SIGINT SIGTERM

filters_help=$(ffmpeg -hide_banner -filters 2>/dev/null || true)
if grep -q "scale_cuda" <<< "$filters_help"; then
    has_scale_cuda=1
else
    has_scale_cuda=0
fi

# Detect whether av1_nvenc supports -highbitdepth
av1_help=$(ffmpeg -hide_banner -h encoder=av1_nvenc 2>/dev/null || true)
if grep -q "highbitdepth" <<< "$av1_help"; then
    HAS_AV1_HIGHBITDEPTH=1
else
    HAS_AV1_HIGHBITDEPTH=0
fi

declare -a file_queue=()
for item in "${targets[@]}"; do
    if [ -d "$item" ]; then
        if [ -n "$CUSTOM_OUT_DIR" ]; then
            while IFS= read -r -d '' f; do
                file_queue+=("$f")
            done < <(find "$item" \
                -path "$ORIG_ROOT" -prune -o \
                -path "$LOG_DIR" -prune -o \
                -path "$CUSTOM_OUT_DIR" -prune -o \
                -type d \( -name "_orig" -o -name "orig" -o -name "_log" \) -prune -o \
                -type f \( -iname "*.mp4" -o -iname "*.mov" \) ! -name ".*_tmp.*" -print0 | sort -z)
        else
            while IFS= read -r -d '' f; do
                file_queue+=("$f")
            done < <(find "$item" \
                -path "$ORIG_ROOT" -prune -o \
                -path "$LOG_DIR" -prune -o \
                -type d \( -name "_orig" -o -name "orig" -o -name "_log" \) -prune -o \
                -type f \( -iname "*.mp4" -o -iname "*.mov" \) ! -name ".*_tmp.*" -print0 | sort -z)
        fi
    elif [ -f "$item" ]; then
        file_queue+=("$item")
    else
        ui_info "Skipping '$item': Path does not exist."
    fi
done

if [ "${#file_queue[@]}" -eq 0 ]; then
    printf "QUIT\n" >&4 2>/dev/null || true
    exec 4>&- 2>/dev/null || true
    wait "$DISPLAY_PID" 2>/dev/null || true
    rm -rf "$UI_DIR"
    echo "Error: No matching .mp4/.mov files found." >&2
    exit 1
fi

FREE_SLOT=0
acquire_slot() {
    local req_weight="$1"
    while true; do
        local active_weight=0
        local first_free=-1

        for (( s=0; s<MAX_JOBS; s++ )); do
            local pid="${slot_pids[$s]}"
            if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
                active_weight=$(( active_weight + slot_weights[$s] ))
            else
                slot_pids[$s]=""
                slot_tmps[$s]=""
                slot_weights[$s]=0
                if [ "$first_free" -eq -1 ]; then
                    first_free="$s"
                fi
            fi
        done

        if [ "$first_free" -ne -1 ] && [ $(( active_weight + req_weight )) -le "$MAX_WEIGHT" ]; then
            FREE_SLOT="$first_free"
            return
        fi
        sleep 0.2
    done
}

handle_ffmpeg_stream() {
    local slot="$1"
    local short_name="$2"
    local total_dur="$3"
    local rel_path="$4"
    local slot_file="${UI_DIR}/slot_${slot}.txt"
    local slot_tmp="${UI_DIR}/slot_${slot}.awk.tmp"
    local slot_num=$(( slot + 1 ))

    awk -v slot_num="$slot_num" \
        -v label="$short_name" \
        -v rel_path="$rel_path" \
        -v dur="$total_dur" \
        -v slot_file="$slot_file" \
        -v slot_tmp="$slot_tmp" \
        -v enable_log="$ENABLE_LOG" \
        -v results_log="$RESULTS_LOG" '
    BEGIN {
        RS="\r|\n"
        timing_warn_count = 0
    }
    {
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0)
        if (length($0) == 0) next

        if ($0 ~ /^frame=[[:space:]]*[0-9]+/) {
            if (enable_log == 1) {
                print $0 >> results_log
                fflush(results_log)
            }

            line = $0
            gsub(/[[:space:]]+/, " ", line)
            gsub(/=[[:space:]]+/, "=", line)

            pct_str = " --.-%"
            eta_str = "ETA --:--"

            if (dur > 0 && match(line, /time=[0-9]+:[0-9]+:[0-9]+(\.[0-9]+)?/)) {
                t_val = substr(line, RSTART + 5, RLENGTH - 5)
                split(t_val, tc, ":")
                cur_sec = tc[1] * 3600 + tc[2] * 60 + tc[3]

                pct = (cur_sec / dur) * 100
                if (pct > 100) pct = 100.0
                pct_str = sprintf("%5.1f%%", pct)

                if (match(line, /speed=[0-9.]+x/)) {
                    sp_val = substr(line, RSTART + 6, RLENGTH - 7) + 0
                    if (sp_val > 0.001) {
                        rem_sec = int((dur - cur_sec) / sp_val)
                        if (rem_sec < 0) rem_sec = 0
                        eh = int(rem_sec / 3600)
                        em = int((rem_sec % 3600) / 60)
                        es = int(rem_sec % 60)
                        if (eh > 0) {
                            eta_str = sprintf("ETA %d:%02d:%02d", eh, em, es)
                        } else {
                            eta_str = sprintf("ETA %02d:%02d", em, es)
                        }
                    }
                }
            }

            printf "[Slot %d] %-20s | %s (%s) | %s\n", slot_num, label, pct_str, eta_str, line > slot_tmp
            close(slot_tmp)
            system("mv -f \"" slot_tmp "\" \"" slot_file "\"")
            print "REFRESH"
            fflush()
            next
        }

        low = tolower($0)
        if (low ~ /non-monotonic dts/ ||
            low ~ /non-monotonous dts/ ||
            low ~ /pts < dts/ ||
            low ~ /dts > pts/ ||
            low ~ /invalid dts/ ||
            low ~ /timestamp discontinuity/ ||
            low ~ /past duration .* too large/ ||
            low ~ /clipping frame in rate conversion/ ||
            low ~ /out of order dts/ ||
            low ~ /stts/ ||
            low ~ /edit list/ ||
            low ~ /multiple edit list/) {
            timing_warn_count++
            next
        }

        if (enable_log == 1) {
            print $0 >> results_log
            fflush(results_log)
        }
        printf "ERR:[Slot %d] %s\n", slot_num, $0
        fflush()
    }
    END {
        if (timing_warn_count > 0) {
            msg = sprintf("[Slot %d | Notice] '\''%s'\'': Suppressed %d timing/DTS mismatch warning(s) (lossless-cut / VFR splice).", slot_num, rel_path, timing_warn_count)
            if (enable_log == 1) {
                print msg >> results_log
                fflush(results_log)
            }
            printf "MSG:%s\n", msg
            fflush()
        }
    }' >&4
}

# Tier 1: Archival 100% GPU (NVDEC -> scale_cuda 10-bit p010le -> av1_nvenc 10-bit)
# Uses -extra_hw_frames 10 (20 base + 10 = 30 <= 32 NVDEC hardware surface limit)
run_av1_10bit_cuda() {
    local slot="$1"
    local short_name="$2"
    local total_dur="$3"
    local rel_path="$4"
    local in_file="$5"
    local out_file="$6"
    local preset="$7"
    local cq="$8"
    local maxrate="$9"
    local bufsize="${10}"
    local c_prim="${11}"
    local c_trc="${12}"
    local c_spc="${13}"

    local -a ext_flags=()
    [ "$HAS_AV1_HIGHBITDEPTH" -eq 1 ] && ext_flags+=(-highbitdepth 1)

    ffmpeg -nostdin -hide_banner -loglevel warning -stats -stats_period 0.5 -y \
        -ignore_unknown -reinit_filter 0 -noautorotate \
        -threads 1 -hwaccel cuda -hwaccel_output_format cuda -extra_hw_frames 10 \
        -i "$in_file" \
        -map_metadata 0 \
        -map 0:v:0 -map 0:a? -map 0:s? \
        -vf "scale_cuda=format=p010le:passthrough=0" \
        -c:v av1_nvenc -preset "$preset" -tune hq "${ext_flags[@]}" \
        -rc vbr -cq "$cq" -b:v 0 -maxrate "${maxrate}k" -bufsize "${bufsize}k" \
        -multipass qres -rc-lookahead 20 -bf 4 -b_ref_mode middle \
        -spatial-aq 1 -aq-strength 8 -temporal-aq 1 \
        -color_primaries "$c_prim" -color_trc "$c_trc" -colorspace "$c_spc" \
        -fps_mode passthrough \
        -tag:v av01 \
        -c:a copy \
        -c:s mov_text \
        -f mp4 -movflags +faststart+use_metadata_tags \
        "$out_file" 2> >(handle_ffmpeg_stream "$slot" "$short_name" "$total_dur" "$rel_path")
}

# Tier 2: Archival 100% GPU Zero-Copy (NVDEC -> av1_nvenc with internal 10-bit promotion)
run_av1_8bit_zerocopy() {
    local slot="$1"
    local short_name="$2"
    local total_dur="$3"
    local rel_path="$4"
    local in_file="$5"
    local out_file="$6"
    local preset="$7"
    local cq="$8"
    local maxrate="$9"
    local bufsize="${10}"
    local c_prim="${11}"
    local c_trc="${12}"
    local c_spc="${13}"

    local -a ext_flags=()
    [ "$HAS_AV1_HIGHBITDEPTH" -eq 1 ] && ext_flags+=(-highbitdepth 1)

    ffmpeg -nostdin -hide_banner -loglevel warning -stats -stats_period 0.5 -y \
        -ignore_unknown -reinit_filter 0 -noautorotate \
        -threads 1 -hwaccel cuda -hwaccel_output_format cuda -extra_hw_frames 10 \
        -i "$in_file" \
        -map_metadata 0 \
        -map 0:v:0 -map 0:a? -map 0:s? \
        -c:v av1_nvenc -preset "$preset" -tune hq "${ext_flags[@]}" \
        -rc vbr -cq "$cq" -b:v 0 -maxrate "${maxrate}k" -bufsize "${bufsize}k" \
        -multipass qres -rc-lookahead 20 -bf 4 -b_ref_mode middle \
        -spatial-aq 1 -aq-strength 8 -temporal-aq 1 \
        -color_primaries "$c_prim" -color_trc "$c_trc" -colorspace "$c_spc" \
        -fps_mode passthrough \
        -tag:v av01 \
        -c:a copy \
        -c:s mov_text \
        -f mp4 -movflags +faststart+use_metadata_tags \
        "$out_file" 2> >(handle_ffmpeg_stream "$slot" "$short_name" "$total_dur" "$rel_path")
}

# Tier 3a: CPU Decode -> GPU hwupload_cuda + scale_cuda (p010le) -> GPU av1_nvenc 10-bit
# Prepends format=nv12 before hwupload_cuda so both 8-bit yuv420p and 10-bit yuv420p10le upload cleanly
run_av1_cpu_decode_gpu_scale() {
    local slot="$1"
    local short_name="$2"
    local total_dur="$3"
    local rel_path="$4"
    local in_file="$5"
    local out_file="$6"
    local preset="$7"
    local cq="$8"
    local maxrate="$9"
    local bufsize="${10}"
    local c_prim="${11}"
    local c_trc="${12}"
    local c_spc="${13}"

    local -a ext_flags=()
    [ "$HAS_AV1_HIGHBITDEPTH" -eq 1 ] && ext_flags+=(-highbitdepth 1)

    ffmpeg -nostdin -hide_banner -loglevel warning -stats -stats_period 0.5 -y \
        -init_hw_device cuda=gpu:0 -filter_hw_device gpu \
        -ignore_unknown -fflags +genpts -reinit_filter 0 -noautorotate \
        -threads $T3B_THREAD_CNT -i "$in_file" \
        -map_metadata 0 \
        -map 0:v:0 -map 0:a? -map 0:s? \
        -vf "crop=trunc(iw/2)*2:trunc(ih/2)*2:0:0,format=p010le,hwupload_cuda,scale_cuda=format=p010le:passthrough=0" \
        -c:v av1_nvenc -preset "$preset" -tune hq "${ext_flags[@]}" \
        -rc vbr -cq "$cq" -b:v 0 -maxrate "${maxrate}k" -bufsize "${bufsize}k" \
        -multipass qres -rc-lookahead 20 -bf 4 -b_ref_mode middle \
        -spatial-aq 1 -aq-strength 8 -temporal-aq 1 \
        -color_primaries "$c_prim" -color_trc "$c_trc" -colorspace "$c_spc" \
        -fps_mode vfr \
        -tag:v av01 \
        -c:a copy \
        -c:s mov_text \
        -f mp4 -movflags +faststart+use_metadata_tags \
        "$out_file" 2> >(handle_ffmpeg_stream "$slot" "$short_name" "$total_dur" "$rel_path")
}

# Tier 3b: CPU Decode -> Lossless Planar Bit-Shift (p010le) -> GPU av1_nvenc 10-bit
run_av1_cpu_decode_fast() {
    local slot="$1"
    local short_name="$2"
    local total_dur="$3"
    local rel_path="$4"
    local in_file="$5"
    local out_file="$6"
    local preset="$7"
    local cq="$8"
    local maxrate="$9"
    local bufsize="${10}"
    local c_prim="${11}"
    local c_trc="${12}"
    local c_spc="${13}"

    local -a ext_flags=()
    [ "$HAS_AV1_HIGHBITDEPTH" -eq 1 ] && ext_flags+=(-highbitdepth 1)

    ffmpeg -nostdin -hide_banner -loglevel warning -stats -stats_period 0.5 -y \
        -ignore_unknown -fflags +genpts -noautorotate \
        -threads $T3B_THREAD_CNT -i "$in_file" \
        -map_metadata 0 \
        -map 0:v:0 -map 0:a? -map 0:s? \
        -vf "crop=trunc(iw/2)*2:trunc(ih/2)*2:0:0,format=p010le" \
        -c:v av1_nvenc -preset "$preset" -tune hq "${ext_flags[@]}" \
        -rc vbr -cq "$cq" -b:v 0 -maxrate "${maxrate}k" -bufsize "${bufsize}k" \
        -multipass qres -rc-lookahead 20 -bf 4 -b_ref_mode middle \
        -spatial-aq 1 -aq-strength 8 -temporal-aq 1 \
        -color_primaries "$c_prim" -color_trc "$c_trc" -colorspace "$c_spc" \
        -fps_mode vfr \
        -tag:v av01 \
        -c:a copy \
        -c:s mov_text \
        -f mp4 -movflags +faststart+use_metadata_tags \
        -threads $T3B_THREAD_CNT \
        "$out_file" 2> >(handle_ffmpeg_stream "$slot" "$short_name" "$total_dur" "$rel_path")
}

make_short_label() {
    local rel="$1"
    local base_name parent_dir id_token
    base_name="${rel##*/}"
    base_name="${base_name%.*}"
    parent_dir=$(dirname "$rel")
    id_token="${base_name%% *}"
    if [ "$parent_dir" != "." ] && [ "${#parent_dir}" -le 10 ]; then
        echo "${parent_dir}/${id_token:0:12}"
    else
        echo "${id_token:0:20}"
    fi
}

start_encode() {
    local f="$1"

    if [ ! -f "$f" ]; then
        return
    fi

    local abs_f rel_path
    abs_f=$(realpath "$f")

    if [[ "$abs_f" == "$ORIG_ROOT"/* ]]; then
        return
    fi
    if [ -n "$CUSTOM_OUT_DIR" ] && [[ "$abs_f" == "$CUSTOM_OUT_DIR"/* ]]; then
        return
    fi

    rel_path=$(realpath --relative-to="$(pwd)" "$abs_f")
    local sub_rel="$rel_path"
    if [[ "$rel_path" == ..* ]]; then
        sub_rel="external/${abs_f#/}"
    fi

    local dir base tmp_out backup_path backup_dir final_out final_out_dir dest_desc
    dir=$(dirname "$abs_f")
    base=$(basename "$abs_f")
    backup_path="${ORIG_ROOT}/${sub_rel}"
    backup_dir=$(dirname "$backup_path")

    if [ -n "$CUSTOM_OUT_DIR" ]; then
        final_out="${CUSTOM_OUT_DIR}/${sub_rel}"
        final_out_dir=$(dirname "$final_out")
        tmp_out="${final_out_dir}/.${base}.av1_tmp.mp4"
        dest_desc="Output     -> $final_out (Original kept in place)"
    else
        final_out="$abs_f"
        final_out_dir="$dir"
        tmp_out="${dir}/.${base}.av1_tmp.mp4"
        dest_desc="In-Place   -> $rel_path (Original -> _orig/$sub_rel)"
    fi

    local probe_out codec="" width=0 height=0 pix_fmt="" refs=0 br="" dur_sec=0 fmt_br=""
    local color_primaries="" color_transfer="" color_space=""
    probe_out=$(ffprobe -v error -select_streams v:0 \
        -show_entries stream=codec_name,width,height,pix_fmt,refs,bit_rate,color_primaries,color_transfer,color_space \
        -show_entries format=duration,bit_rate \
        -of default=noprint_wrappers=1 "$abs_f" 2>/dev/null | tr -d '\r' || true)

    if [ -z "$probe_out" ]; then
        ui_err "Skipping '$rel_path': Could not read video stream via ffprobe."
        log_failed "$rel_path"
        return
    fi

    while IFS='=' read -r k v; do
        case "$k" in
            codec_name)      [ -z "$codec" ] && codec="$v" ;;
            width)           [ "$width" -eq 0 ] && [[ "$v" =~ ^[0-9]+$ ]] && width="$v" ;;
            height)          [ "$height" -eq 0 ] && [[ "$v" =~ ^[0-9]+$ ]] && height="$v" ;;
            pix_fmt)         [ -z "$pix_fmt" ] && pix_fmt="$v" ;;
            refs)            [ "$refs" -eq 0 ] && [[ "$v" =~ ^[0-9]+$ ]] && refs="$v" ;;
            color_primaries) [ -z "$color_primaries" ] && color_primaries="$v" ;;
            color_transfer)  [ -z "$color_transfer" ] && color_transfer="$v" ;;
            color_space)     [ -z "$color_space" ] && color_space="$v" ;;
            bit_rate)
                if [ -z "$br" ] && [[ "$v" =~ ^[0-9]+$ ]]; then
                    br="$v"
                elif [[ "$v" =~ ^[0-9]+$ ]]; then
                    fmt_br="$v"
                fi
                ;;
            duration)        [[ "$v" =~ ^[0-9]+(\.[0-9]+)?$ ]] && dur_sec="$v" ;;
        esac
    done <<< "$probe_out"

    if [ -z "$codec" ] || [ "$width" -eq 0 ]; then
        ui_err "Skipping '$rel_path': No valid video stream found."
        log_failed "$rel_path"
        return
    fi

    if [ "$codec" = "av1" ]; then
        ui_info "Skipping '$rel_path': Already encoded in AV1."
        return
    fi

    if [ "$codec" = "hevc" ] && [ "$ALLOW_HEVC" -eq 0 ]; then
        ui_info "Skipping '$rel_path': Already encoded in HEVC (pass --allow-hevc to force HEVC -> AV1)."
        return
    fi

    if [ -n "$CUSTOM_OUT_DIR" ]; then
        if [ -e "$final_out" ]; then
            ui_info "Skipping '$rel_path': Output already exists at '$final_out'."
            return
        fi
    else
        if [ -e "$backup_path" ]; then
            ui_info "Skipping '$rel_path': Backup already exists at '$backup_path'."
            return
        fi
    fi

    if [[ ! "${br:-}" =~ ^[0-9]+$ ]]; then
        br="${fmt_br:-5000000}"
    fi
    if [[ ! "${br:-}" =~ ^[0-9]+$ ]]; then
        br=5000000
    fi

    local c_prim="${color_primaries:-bt709}"
    local c_trc="${color_transfer:-bt709}"
    local c_spc="${color_space:-bt709}"
    [[ "$c_prim" == "unknown" || "$c_prim" == "N/A" || "$c_prim" == "reserved" ]] && c_prim="bt709"
    [[ "$c_trc"  == "unknown" || "$c_trc"  == "N/A" || "$c_trc"  == "reserved" ]] && c_trc="bt709"
    [[ "$c_spc"  == "unknown" || "$c_spc"  == "N/A" || "$c_spc"  == "reserved" ]] && c_spc="bt709"

    local br_kbps=$(( br / 1000 ))
    local max_dim="$width"
    if [ "$height" -gt "$max_dim" ]; then
        max_dim="$height"
    fi

    # Matches 264to265.sh speed & quality architecture (p5, hq, qres, lookahead 20)
    # CQ 23/24 matches HEVC CQ 21/22 fidelity while delivering 15-22% smaller files
    local preset cq maxrate bufsize job_weight
    preset="p5"
    if [ "$max_dim" -ge 3840 ]; then
        cq=24
        maxrate=$(( br_kbps * 52 / 100 ))
        job_weight=2
    elif [ "$br_kbps" -gt 5500 ]; then
        cq=23
        maxrate=$(( br_kbps * 48 / 100 ))
        job_weight=1
    else
        cq=24
        maxrate=$(( br_kbps * 58 / 100 ))
        job_weight=1
    fi
    bufsize=$(( maxrate * 2 ))

    acquire_slot "$job_weight"
    local my_slot="$FREE_SLOT"
    local slot_num=$(( my_slot + 1 ))
    local short_label
    short_label=$(make_short_label "$rel_path")

    update_slot_status "$my_slot" "[Slot ${slot_num}] $(printf '%-20s' "$short_label") |   0.0% (ETA --:--) | Starting..."

    ui_info "============================================================
[Starting Slot ${slot_num}] : $rel_path
Source            : ${width}x${height} | ${br_kbps} kbps | $codec ($pix_fmt, ${refs:-0} refs, $c_prim)
Target            : NVENC AV1 10-bit ($preset, hq, qres, temporal-aq) | CQ $cq | Maxrate ${maxrate}k
Destination       : $dest_desc
============================================================"

    (
        mkdir -p "$final_out_dir"
        encode_ok=0

        # Tier 1: Full GPU pipeline (NVDEC -> scale_cuda 10-bit -> av1_nvenc 10-bit)
        if [ "$has_scale_cuda" -eq 1 ]; then
            if run_av1_10bit_cuda "$my_slot" "$short_label" "$dur_sec" "$rel_path" "$abs_f" "$tmp_out" "$preset" "$cq" "$maxrate" "$bufsize" "$c_prim" "$c_trc" "$c_spc" && [ -s "$tmp_out" ]; then
                encode_ok=1
            else
                rm -f "$tmp_out"
            fi
        fi

        # Tier 2: Filterless GPU Zero-Copy
        if [ "$encode_ok" -eq 0 ]; then
            ui_info "[Slot ${slot_num} | Retry Tier 2] Running filterless Zero-Copy CUDA on '$rel_path'..."
            if run_av1_8bit_zerocopy "$my_slot" "$short_label" "$dur_sec" "$rel_path" "$abs_f" "$tmp_out" "$preset" "$cq" "$maxrate" "$bufsize" "$c_prim" "$c_trc" "$c_spc" && [ -s "$tmp_out" ]; then
                encode_ok=1
            else
                rm -f "$tmp_out"
            fi
        fi

        # Tier 3: CPU Decode -> GPU av1_nvenc (tries GPU scale_cuda first, then lossless CPU bit-shift)
        if [ "$encode_ok" -eq 0 ]; then
            if [ "$ENABLE_TIER3" -eq 1 ]; then
                if [ "$has_scale_cuda" -eq 1 ]; then
                    ui_info "[Slot ${slot_num} | Retry Tier 3a] NVDEC rejected stream; running CPU decode -> GPU scale_cuda (10-bit) -> AV1 NVENC on '$rel_path'..."
                    if run_av1_cpu_decode_gpu_scale "$my_slot" "$short_label" "$dur_sec" "$rel_path" "$abs_f" "$tmp_out" "$preset" "$cq" "$maxrate" "$bufsize" "$c_prim" "$c_trc" "$c_spc" && [ -s "$tmp_out" ]; then
                        encode_ok=1
                    else
                        rm -f "$tmp_out"
                    fi
                fi

                if [ "$encode_ok" -eq 0 ]; then
                    ui_info "[Slot ${slot_num} | Retry Tier 3b] Running CPU decode (lossless 10-bit shift) -> GPU AV1 NVENC on '$rel_path'..."
                    if run_av1_cpu_decode_fast "$my_slot" "$short_label" "$dur_sec" "$rel_path" "$abs_f" "$tmp_out" "$preset" "$cq" "$maxrate" "$bufsize" "$c_prim" "$c_trc" "$c_spc" && [ -s "$tmp_out" ]; then
                        encode_ok=1
                    else
                        rm -f "$tmp_out"
                    fi
                fi
            else
                ui_info "[Slot ${slot_num} | Skip Tier 3] Tier 1 & 2 failed and Tier 3 (CPU decode) is disabled. Adding '$rel_path' to failed list."
                rm -f "$tmp_out"
                log_failed "$rel_path"
                update_slot_status "$my_slot" "[Slot ${slot_num}] Idle"
                exit 0
            fi
        fi

        if [ "$encode_ok" -eq 1 ] && [ -s "$tmp_out" ]; then
            touch -r "$abs_f" "$tmp_out"

            if [ -n "$CUSTOM_OUT_DIR" ]; then
                if mv -f "$tmp_out" "$final_out"; then
                    touch -r "$abs_f" "$final_out"
                    ui_info "[Done Slot ${slot_num}] Saved converted AV1 file to '$final_out' (mtime preserved, original untouched)"
                else
                    ui_err "[Error Slot ${slot_num}] Could not move temp file to '$final_out'."
                    log_failed "$rel_path"
                fi
            else
                mkdir -p "$backup_dir"
                if mv -n "$abs_f" "$backup_path"; then
                    mv -f "$tmp_out" "$abs_f"
                    touch -r "$backup_path" "$abs_f"
                    ui_info "[Done Slot ${slot_num}] Replaced '$rel_path' with AV1 (mtime preserved, original backed up to '_orig/$sub_rel')"
                else
                    ui_err "[Error Slot ${slot_num}] Could not move original '$rel_path' to '$backup_path'. Keeping temp file."
                    log_failed "$rel_path"
                fi
            fi
        else
            ui_err "[Error Slot ${slot_num}] All enabled tiers failed to convert '$rel_path'. Removing incomplete temp file."
            rm -f "$tmp_out"
            log_failed "$rel_path"
        fi

        update_slot_status "$my_slot" "[Slot ${slot_num}] Idle"
    ) &

    slot_pids[$my_slot]="$!"
    slot_tmps[$my_slot]="$tmp_out"
    slot_weights[$my_slot]="$job_weight"
}

for f in "${file_queue[@]}"; do
    start_encode "$f"
done

for pid in "${slot_pids[@]}"; do
    if [ -n "$pid" ]; then
        wait "$pid" 2>/dev/null || true
    fi
done

printf "QUIT\n" >&4
exec 4>&-
wait "$DISPLAY_PID" 2>/dev/null || true
rm -rf "$UI_DIR"

if [ -n "$CUSTOM_OUT_DIR" ]; then
    echo "All conversions finished. Converted AV1 files saved in: $CUSTOM_OUT_DIR"
else
    echo "All conversions finished. Original files are backed up in: $ORIG_ROOT"
fi
if [ "$ENABLE_LOG" -eq 1 ]; then
    echo "Full log saved to: $RESULTS_LOG"
fi
if [ -s "$FAILED_LOG" ]; then
    echo "Skipped/failed files recorded in: $FAILED_LOG"
    if [ "$ENABLE_TIER3" -eq 0 ]; then
        echo "Tip: Run '${0##*/} -3 \$(tr '\\n' ' ' < _log/failed.txt)' later to process Tier 3 files."
    fi
fi
