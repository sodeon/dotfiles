#!/usr/bin/env bash
set -uo pipefail

# Maximum UI/worker slots (4 slots total for Dual-NVENC RTX 5070 Ti)
MAX_JOBS=4
T3B_THREAD_CNT=4
# Weighted concurrency capacity (MAX_WEIGHT=6 for Dual-NVENC):
# - FHD weight = 1 -> 4x FHD = 4 <= 6 (4 streams, 2 per NVENC)
# - 4K  weight = 2 -> 3x 4K  = 6 <= 6 (3 streams across 2 NVENC)
# - Mixed          -> 2x 4K (4) + 2x FHD (2) = 6 <= 6 (4 streams)
MAX_WEIGHT=6

# Default toggle for Tier 3 (CPU decode -> GPU NVENC): 0 = disabled (default), 1 = enabled
ENABLE_TIER3=0

ORIG_ROOT="$(pwd)/_orig"
CUSTOM_OUT_DIR=""
LOG_DIR="$(pwd)/_log"
RESULTS_LOG="${LOG_DIR}/results.txt"
FAILED_LOG="${LOG_DIR}/failed.txt"
AV1_LOG="${LOG_DIR}/av1_skipped.txt"

ENABLE_LOG=0
SUPPRESS_ERRORS=0

usage() {
    echo "Usage: ${0##*/} [-l|--log] [-s|--suppress-errors] [-3|--tier3] [--no-tier3] [-o|--output <dir>] <.|file1.mp4|*.mp4|folder1 ...>"
    echo
    echo "Options:"
    echo "  -o, --output <dir>     Write converted files to <dir> instead of replacing in-place (originals untouched)"
    echo "  -l, --log              Write output (info + errors) to ./_log/results.txt"
    echo "  -s, --suppress-errors  Hide errors on terminal while keeping info & multi-line progress bars"
    echo "  -3, --tier3            Enable Tier 3 fallback (CPU decode -> GPU 10-bit encode)"
    echo "      --no-tier3         Disable Tier 3 fallback (default; logs skipped files to ./_log/failed.txt)"
    echo "  -h, --help             Show this help message"
    echo
    echo "Examples:"
    echo "  ${0##*/} .                        # In-place convert all .mp4/.mov files (originals moved to ./_orig)"
    echo "  ${0##*/} -o /mnt/d/HEVC_Out .     # Convert all into /mnt/d/HEVC_Out, leaving originals untouched"
    echo "  ${0##*/} -l3s -o ./out FolderA/   # Convert FolderA into ./out with logging & Tier 3 enabled"
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
                        # Support -ls -o <dir> or combined -lso <dir> if 'o' is at the end
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
        echo "Session Started: $(date '+%Y-%m-%d %H:%M:%S') (Tier 3: $ENABLE_TIER3 | Output: ${CUSTOM_OUT_DIR:-In-Place})"
        echo "===================================================================="
    } >> "$RESULTS_LOG"
fi

# Set up temporary workspace for per-slot progress lines and synchronized terminal output
UI_DIR=$(mktemp -d)
UI_FIFO="${UI_DIR}/ui.fifo"
mkfifo "$UI_FIFO"

for (( s=0; s<MAX_JOBS; s++ )); do
    echo "[Slot $((s+1))] Idle" > "${UI_DIR}/slot_${s}.txt"
done

# Background Display Manager:
# Uses ANSI \033[?7l (disable line wrap) while drawing progress bars so long lines never wrap or break cursor math
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

log_av1() {
    local rel="$1"
    mkdir -p "$LOG_DIR"
    if [ ! -f "$AV1_LOG" ] || ! grep -Fxq "$rel" "$AV1_LOG"; then
        echo "$rel" >> "$AV1_LOG"
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

# Auto-detect Dual-NVENC split_encode_mode support (FFmpeg >= 6.1 / nv-codec-headers >= 12.1)
nvenc_help=$(ffmpeg -hide_banner -h encoder=hevc_nvenc 2>/dev/null || true)
declare -a split_enc_args=()
if grep -q "split_encode_mode" <<< "$nvenc_help"; then
    split_enc_args=(-split_encode_mode 2)
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
                -type f \( -iname "*.mp4" -o -iname "*.mov" \) ! -name ".*.hevc_tmp.mp4" -print0 | sort -z)
        else
            while IFS= read -r -d '' f; do
                file_queue+=("$f")
            done < <(find "$item" \
                -path "$ORIG_ROOT" -prune -o \
                -path "$LOG_DIR" -prune -o \
                -type d \( -name "_orig" -o -name "orig" -o -name "_log" \) -prune -o \
                -type f \( -iname "*.mp4" -o -iname "*.mov" \) ! -name ".*.hevc_tmp.mp4" -print0 | sort -z)
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

# Dynamic Concurrency Scheduler (MAX_JOBS=4, MAX_WEIGHT=6):
# - FHD weight = 1 -> up to 4x FHD concurrently (1+1+1+1 = 4 <= 6)
# - 4K  weight = 2 -> up to 3x 4K concurrently  (2+2+2   = 6 <= 6)
# - Mixed          -> allows 2x 4K + 2x FHD     (2+2+1+1 = 6 <= 6)
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
        sleep 0.05
    done
}

# Routes FFmpeg stderr for a specific slot:
# - Computes live % completed and ETA from time= and speed=
# - Suppresses repetitive lossless-cut / camera timing / DTS mismatch spam from both terminal and log,
#   emitting a single one-line notice when the stream finishes.
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

            # Extract time=HH:MM:SS.xx
            if (dur > 0 && match(line, /time=[0-9]+:[0-9]+:[0-9]+(\.[0-9]+)?/)) {
                t_val = substr(line, RSTART + 5, RLENGTH - 5)
                split(t_val, tc, ":")
                cur_sec = tc[1] * 3600 + tc[2] * 60 + tc[3]

                pct = (cur_sec / dur) * 100
                if (pct > 100) pct = 100.0
                pct_str = sprintf("%5.1f%%", pct)

                # Extract speed=X.XXx to calculate remaining wall-clock ETA
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

        # Detect timing/timestamp mismatch messages typical of lossless-cut splices or VFR camera buffers
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

# Tier 1: Archival 100% GPU (NVDEC -> scale_cuda 10-bit -> NVENC main10)
run_nvenc_10bit_cuda() {
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

    ffmpeg -nostdin -hide_banner -loglevel warning -stats -stats_period 0.5 -y \
        -ignore_unknown -reinit_filter 0 -noautorotate \
        -hwaccel cuda -hwaccel_output_format cuda -extra_hw_frames 32 \
        -i "$in_file" \
        -map_metadata 0 \
        -map 0:v:0 -map 0:a? -map 0:s? \
        -vf "scale_cuda=format=p010le:passthrough=0" \
        -c:v hevc_nvenc -profile:v main10 -preset "$preset" -tune hq "${split_enc_args[@]}" \
        -rc vbr -cq "$cq" -b:v 0 -maxrate "${maxrate}k" -bufsize "${bufsize}k" \
        -multipass qres -rc-lookahead 20 -bf 4 -b_ref_mode middle \
        -spatial-aq 1 -aq-strength 8 -temporal-aq 1 \
        -color_primaries "$c_prim" -color_trc "$c_trc" -colorspace "$c_spc" \
        -fps_mode passthrough \
        -tag:v hvc1 \
        -c:a copy \
        -c:s mov_text \
        -movflags +faststart+use_metadata_tags \
        "$out_file" 2> >(handle_ffmpeg_stream "$slot" "$short_name" "$total_dur" "$rel_path")
}

# Tier 2: Archival 100% GPU Zero-Copy 8-bit (NVDEC -> NVENC main)
run_nvenc_8bit_zerocopy() {
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

    ffmpeg -nostdin -hide_banner -loglevel warning -stats -stats_period 0.5 -y \
        -ignore_unknown -reinit_filter 0 -noautorotate \
        -hwaccel cuda -hwaccel_output_format cuda -extra_hw_frames 32 \
        -i "$in_file" \
        -map_metadata 0 \
        -map 0:v:0 -map 0:a? -map 0:s? \
        -c:v hevc_nvenc -profile:v main -preset "$preset" -tune hq "${split_enc_args[@]}" \
        -rc vbr -cq "$cq" -b:v 0 -maxrate "${maxrate}k" -bufsize "${bufsize}k" \
        -multipass qres -rc-lookahead 20 -bf 4 -b_ref_mode middle \
        -spatial-aq 1 -aq-strength 8 -temporal-aq 1 \
        -color_primaries "$c_prim" -color_trc "$c_trc" -colorspace "$c_spc" \
        -fps_mode passthrough \
        -tag:v hvc1 \
        -c:a copy \
        -c:s mov_text \
        -movflags +faststart+use_metadata_tags \
        "$out_file" 2> >(handle_ffmpeg_stream "$slot" "$short_name" "$total_dur" "$rel_path")
}

# Tier 3a: CPU Decode -> GPU hwupload_cuda + scale_cuda (p010le) -> GPU NVENC main10
run_nvenc_cpu_decode_gpu_scale() {
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

    ffmpeg -nostdin -hide_banner -loglevel warning -stats -stats_period 0.5 -y \
        -init_hw_device cuda=gpu:0 -filter_hw_device gpu \
        -ignore_unknown -fflags +genpts -reinit_filter 0 -noautorotate \
        -i "$in_file" \
        -map_metadata 0 \
        -map 0:v:0 -map 0:a? -map 0:s? \
        -vf "crop=trunc(iw/2)*2:trunc(ih/2)*2:0:0,hwupload_cuda,scale_cuda=format=p010le:passthrough=0" \
        -c:v hevc_nvenc -profile:v main10 -preset "$preset" -tune hq "${split_enc_args[@]}" \
        -rc vbr -cq "$cq" -b:v 0 -maxrate "${maxrate}k" -bufsize "${bufsize}k" \
        -multipass qres -rc-lookahead 20 -bf 4 -b_ref_mode middle \
        -spatial-aq 1 -aq-strength 8 -temporal-aq 1 \
        -color_primaries "$c_prim" -color_trc "$c_trc" -colorspace "$c_spc" \
        -fps_mode vfr \
        -tag:v hvc1 \
        -c:a copy \
        -c:s mov_text \
        -movflags +faststart+use_metadata_tags \
        "$out_file" 2> >(handle_ffmpeg_stream "$slot" "$short_name" "$total_dur" "$rel_path")
}

# Tier 3b: CPU Decode -> Lossless Planar Bit-Shift (p010le, zero bgr48le) -> GPU NVENC main10
run_nvenc_cpu_decode_fast() {
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

    ffmpeg -nostdin -hide_banner -loglevel warning -stats -stats_period 0.5 -y \
        -ignore_unknown -fflags +genpts -noautorotate \
        -i "$in_file" \
        -map_metadata 0 \
        -map 0:v:0 -map 0:a? -map 0:s? \
        -vf "crop=trunc(iw/2)*2:trunc(ih/2)*2:0:0,format=p010le" \
        -c:v hevc_nvenc -profile:v main10 -preset "$preset" -tune hq "${split_enc_args[@]}" \
        -rc vbr -cq "$cq" -b:v 0 -maxrate "${maxrate}k" -bufsize "${bufsize}k" \
        -multipass qres -rc-lookahead 20 -bf 4 -b_ref_mode middle \
        -spatial-aq 1 -aq-strength 8 -temporal-aq 1 \
        -color_primaries "$c_prim" -color_trc "$c_trc" -colorspace "$c_spc" \
        -fps_mode vfr \
        -tag:v hvc1 \
        -c:a copy \
        -c:s mov_text \
        -movflags +faststart+use_metadata_tags \
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
        tmp_out="${final_out_dir}/.${base}.hevc_tmp.mp4"
        dest_desc="Output     -> $final_out (Original kept in place)"
    else
        final_out="$abs_f"
        final_out_dir="$dir"
        tmp_out="${dir}/.${base}.hevc_tmp.mp4"
        dest_desc="In-Place   -> $rel_path (Original -> _orig/$sub_rel)"
    fi

    # Query video stream properties and container duration/bitrate in one ffprobe call
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

    if [ "$codec" = "hevc" ]; then
        ui_info "Skipping '$rel_path': Already encoded in H.265 (HEVC)."
        return
    fi

    if [ "$codec" = "av1" ]; then
        ui_info "Skipping '$rel_path': Source is AV1 (recorded in _log/av1_skipped.txt)."
        log_av1 "$rel_path"
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

    # Preserve HDR/SDR color metadata dynamically; map untagged/legacy mobile tags to bt709
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

    # Archival quality preset & concurrency weight (MAX_WEIGHT=6):
    # - 4K+ (max_dim >= 3840): job_weight=2 (max 3x 4K, or 2x 4K + 2x FHD)
    # - FHD (max_dim < 3840):  job_weight=1 (max 4x FHD)
    local preset cq maxrate bufsize job_weight
    preset="p5"
    if [ "$max_dim" -ge 3840 ]; then
        cq=22
        maxrate=$(( br_kbps * 65 / 100 ))
        job_weight=2
    elif [ "$br_kbps" -gt 5500 ]; then
        cq=21
        maxrate=$(( br_kbps * 60 / 100 ))
        job_weight=1
    else
        cq=22
        maxrate=$(( br_kbps * 70 / 100 ))
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
Target            : NVENC HEVC 10-bit ($preset, qres, temporal-aq) | CQ $cq | Maxrate ${maxrate}k
Destination       : $dest_desc
============================================================"

    (
        mkdir -p "$final_out_dir"
        encode_ok=0

        # Tier 1: Full GPU pipeline (NVDEC -> scale_cuda 10-bit -> NVENC main10)
        if [ "$has_scale_cuda" -eq 1 ]; then
            if run_nvenc_10bit_cuda "$my_slot" "$short_label" "$dur_sec" "$rel_path" "$abs_f" "$tmp_out" "$preset" "$cq" "$maxrate" "$bufsize" "$c_prim" "$c_trc" "$c_spc" && [ -s "$tmp_out" ]; then
                encode_ok=1
            else
                rm -f "$tmp_out"
            fi
        fi

        # Tier 2: Filterless GPU Zero-Copy 8-bit
        if [ "$encode_ok" -eq 0 ]; then
            ui_info "[Slot ${slot_num} | Retry Tier 2] Running filterless Zero-Copy CUDA on '$rel_path'..."
            if run_nvenc_8bit_zerocopy "$my_slot" "$short_label" "$dur_sec" "$rel_path" "$abs_f" "$tmp_out" "$preset" "$cq" "$maxrate" "$bufsize" "$c_prim" "$c_trc" "$c_spc" && [ -s "$tmp_out" ]; then
                encode_ok=1
            else
                rm -f "$tmp_out"
            fi
        fi

        # Tier 3: CPU Decode -> GPU NVENC (tries GPU scale_cuda first, then lossless CPU bit-shift)
        if [ "$encode_ok" -eq 0 ]; then
            if [ "$ENABLE_TIER3" -eq 1 ]; then
                if [ "$has_scale_cuda" -eq 1 ]; then
                    ui_info "[Slot ${slot_num} | Retry Tier 3a] NVDEC rejected stream; running CPU decode -> GPU scale_cuda (10-bit) -> NVENC on '$rel_path'..."
                    if run_nvenc_cpu_decode_gpu_scale "$my_slot" "$short_label" "$dur_sec" "$rel_path" "$abs_f" "$tmp_out" "$preset" "$cq" "$maxrate" "$bufsize" "$c_prim" "$c_trc" "$c_spc" && [ -s "$tmp_out" ]; then
                        encode_ok=1
                    else
                        rm -f "$tmp_out"
                    fi
                fi

                if [ "$encode_ok" -eq 0 ]; then
                    ui_info "[Slot ${slot_num} | Retry Tier 3b] Running CPU decode (lossless 10-bit shift) -> GPU NVENC on '$rel_path'..."
                    if run_nvenc_cpu_decode_fast "$my_slot" "$short_label" "$dur_sec" "$rel_path" "$abs_f" "$tmp_out" "$preset" "$cq" "$maxrate" "$bufsize" "$c_prim" "$c_trc" "$c_spc" && [ -s "$tmp_out" ]; then
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
                    ui_info "[Done Slot ${slot_num}] Saved converted file to '$final_out' (mtime preserved, original untouched)"
                else
                    ui_err "[Error Slot ${slot_num}] Could not move temp file to '$final_out'."
                    log_failed "$rel_path"
                fi
            else
                mkdir -p "$backup_dir"
                if mv -n "$abs_f" "$backup_path"; then
                    mv -f "$tmp_out" "$abs_f"
                    touch -r "$backup_path" "$abs_f"
                    ui_info "[Done Slot ${slot_num}] Replaced '$rel_path' (mtime preserved, original backed up to '_orig/$sub_rel')"
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
    echo "All conversions finished. Converted HEVC files saved in: $CUSTOM_OUT_DIR"
else
    echo "All conversions finished. Original H.264 files are backed up in: $ORIG_ROOT"
fi
if [ "$ENABLE_LOG" -eq 1 ]; then
    echo "Full log saved to: $RESULTS_LOG"
fi
if [ -s "$AV1_LOG" ]; then
    echo "Skipped AV1 files recorded in: $AV1_LOG"
fi
if [ -s "$FAILED_LOG" ]; then
    echo "Skipped/failed files recorded in: $FAILED_LOG"
    if [ "$ENABLE_TIER3" -eq 0 ]; then
        echo "Tip: Run '${0##*/} -3 \$(tr '\\n' ' ' < _log/failed.txt)' later to process Tier 3 files."
    fi
fi
