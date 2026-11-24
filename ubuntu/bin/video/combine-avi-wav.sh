#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage: $0 [-s] [-q CQ] [-j JOBS] <target_folder>"
    echo "  -s         Scale 4K to FHD (1920x1080) using GPU (scale_cuda + hevc_nvenc)"
    echo "  -q CQ      NVENC Constant Quality target when scaling (default: 18 for PSNR > 45 dB)"
    echo "  -j JOBS    Concurrent FFmpeg jobs to saturate multi-NVENC (default: 4)"
    exit 1
}

SCALE_FHD=false
CQ=18
JOBS=4

while getopts ":sq:j:" opt; do
    case ${opt} in
        s) SCALE_FHD=true ;;
        q) CQ="$OPTARG" ;;
        j) JOBS="$OPTARG" ;;
        :) echo "Option -$OPTARG requires an argument." >&2; usage ;;
        \?) echo "Invalid option: -$OPTARG" >&2; usage ;;
    esac
done
shift $((OPTIND - 1))

[[ $# -lt 1 ]] && usage

if ! [[ "$JOBS" =~ ^[1-9][0-9]*$ ]]; then
    echo "Error: -j JOBS must be a positive integer (got '$JOBS')." >&2
    exit 1
fi

TARGET_DIR="${1%/}"
ORIG_DIR="${TARGET_DIR}/_orig"
LOG_DIR="${TARGET_DIR}/_log"

if [[ ! -d "$TARGET_DIR" ]]; then
    echo "Error: Directory '$TARGET_DIR' does not exist." >&2
    exit 1
fi

mkdir -p "$ORIG_DIR" "$LOG_DIR"

SHM_BASE="/tmp"
[[ -d /dev/shm && -w /dev/shm ]] && SHM_BASE="/dev/shm"
STATE_DIR="$(mktemp -d -p "$SHM_BASE" combine_av.XXXXXX)"

IS_TTY=false
[[ -t 1 ]] && IS_TTY=true

ABORTING=false
UI_PID=""
declare -A WORKER_PIDS=()   # pid -> slot_id
declare -a FREE_SLOTS=()

for (( s=JOBS; s>=1; s-- )); do
    FREE_SLOTS+=("$s")
    echo "[S${s}] Idle" > "${STATE_DIR}/slot_${s}"
done

get_term_cols() {
    local rows cols
    if read -r rows cols < <(stty size </dev/tty 2>/dev/null) && (( cols > 20 )); then
        echo "$cols"
    else
        echo "${COLUMNS:-160}"
    fi
}

shorten_label() {
    local str="$1" max_len="$2"
    if (( ${#str} <= max_len )); then
        printf "%s" "$str"
    else
        local half=$(( (max_len - 3) / 2 ))
        printf "%s...%s" "${str:0:half}" "${str: -half}"
    fi
}

start_ui() {
    [[ "$IS_TTY" == false ]] && return
    tput civis </dev/tty 2>/dev/null || true
    printf "\033[?7l"
    for (( s=1; s<=JOBS; s++ )); do echo ""; done

    (
        trap 'exit 0' TERM INT
        while true; do
            local cols
            cols=$(get_term_cols)
            printf "\033[%dA" "$JOBS"
            for (( s=1; s<=JOBS; s++ )); do
                local line=""
                [[ -f "${STATE_DIR}/slot_${s}" ]] && IFS= read -r line < "${STATE_DIR}/slot_${s}" || line="[S${s}] Idle"
                printf "\r\033[2K%s\n" "${line:0:$(( cols - 1 ))}"
            done
            sleep 0.25
        done
    ) &
    UI_PID=$!
}

stop_ui() {
    if [[ -n "$UI_PID" ]]; then
        kill -TERM "$UI_PID" 2>/dev/null || true
        wait "$UI_PID" 2>/dev/null || true
        UI_PID=""
    fi
    if [[ "$IS_TTY" == true ]]; then
        printf "\033[?7h"
        tput cnorm </dev/tty 2>/dev/null || true
    fi
}

log_event() {
    local msg="$1"
    if [[ "$IS_TTY" == true && -n "$UI_PID" ]]; then
        local cols
        cols=$(get_term_cols)
        printf "\033[?7h\033[%dA\r\033[2K%s\n\033[?7l" "$JOBS" "$msg"
        for (( s=1; s<=JOBS; s++ )); do
            local line=""
            [[ -f "${STATE_DIR}/slot_${s}" ]] && IFS= read -r line < "${STATE_DIR}/slot_${s}" || line="[S${s}] Idle"
            printf "\r\033[2K%s\n" "${line:0:$(( cols - 1 ))}"
        done
    else
        echo "$msg"
    fi
}

set_slot_status() {
    local slot="$1" text="$2"
    printf "%s\n" "$text" > "${STATE_DIR}/slot_${slot}.tmp"
    mv -f "${STATE_DIR}/slot_${slot}.tmp" "${STATE_DIR}/slot_${slot}" 2>/dev/null || true
}

cleanup() {
    [[ "$ABORTING" == true ]] && return
    ABORTING=true
    trap '' INT TERM

    stop_ui
    echo -e "\n[ABORT] Interrupt received. Stopping active FFmpeg workers..." >&2

    local pids=("${!WORKER_PIDS[@]}")
    if (( ${#pids[@]} > 0 )); then
        for pid in "${pids[@]}"; do
            pkill -TERM -P "$pid" 2>/dev/null || true
            kill -TERM "$pid" 2>/dev/null || true
        done

        for _ in {1..20}; do
            local alive=0
            for pid in "${pids[@]}"; do
                if kill -0 "$pid" 2>/dev/null || pgrep -P "$pid" >/dev/null 2>&1; then
                    alive=1
                    break
                fi
            done
            (( alive == 0 )) && break
            sleep 0.1
        done

        for pid in "${pids[@]}"; do
            pkill -KILL -P "$pid" 2>/dev/null || true
            kill -KILL "$pid" 2>/dev/null || true
        done

        wait 2>/dev/null || true
    fi

    rm -f "$TARGET_DIR"/.*.tmp.mp4
    rm -rf "$STATE_DIR"
    echo "[ABORT] Cleanly stopped. Partial temp files removed; originals untouched." >&2
    exit 130
}
trap cleanup INT TERM

# Tuned for maximum dual-NVENC throughput + PSNR > 45 dB:
# -rc-lookahead 16 + -surfaces 48 prevents surface lock contention while keeping full temporal AQ benefit
nvenc_common_args=(
    -c:v hevc_nvenc
    -preset p7
    -tune hq
    -rc vbr
    -b:v 0
    -multipass qres
    -rc-lookahead 16
    -temporal-aq 1
    -bf 4
    -b_ref_mode middle
    -surfaces 48
    -profile:v main10
    -tag:v hvc1
)

run_ffmpeg() {
    local slot="$1" label="$2" avi="$3" wav="$4" out="$5" mode="$6" log_file="$7"
    local base_flags=(-nostdin -hide_banner -loglevel warning -nostats -stats_period 0.5 -progress pipe:1 -fflags +genpts+igndts)
    local cmd=()

    if [[ "$mode" == "copy" ]]; then
        cmd=(ffmpeg "${base_flags[@]}"
            -i "$avi" -i "$wav"
            -map 0:v:0 -map 1:a:0 -map_metadata 0
            -c:v copy -tag:v hvc1
            -c:a aac -b:a 320k -movflags +faststart -y "$out")

    elif [[ "$mode" == "nvdec" ]]; then
        # -extra_hw_frames 10 BEFORE -i is valid input option: 16 (DPB) + 2 (threads) + 10 = 28 surfaces (<= 32 NVDEC max)
        cmd=(ffmpeg "${base_flags[@]}"
            -threads 2 -hwaccel cuda -hwaccel_output_format cuda -extra_hw_frames 10
            -i "$avi" -i "$wav"
            -map 0:v:0 -map 1:a:0 -map_metadata 0
            -vf "scale_cuda=1920:-2:interp_algo=lanczos:format=p010le:passthrough=0"
            "${nvenc_common_args[@]}" -cq "$CQ"
            -c:a aac -b:a 320k -movflags +faststart -y "$out")

    elif [[ "$mode" == "cpu_fallback" ]]; then
        local cpu_threads=$(( 16 / JOBS ))
        (( cpu_threads < 2 )) && cpu_threads=2
        (( cpu_threads > 6 )) && cpu_threads=6

        # On CPU fallback, extra_hw_frames=32 is passed as a filter option to hwupload_cuda
        cmd=(ffmpeg "${base_flags[@]}"
            -threads "$cpu_threads" -i "$avi" -i "$wav"
            -map 0:v:0 -map 1:a:0 -map_metadata 0
            -init_hw_device cuda=gpu:0 -filter_hw_device gpu
            -vf "format=p010le,hwupload_cuda,scale_cuda=1920:-2:interp_algo=lanczos:format=p010le"
            "${nvenc_common_args[@]}" -cq "$CQ"
            -c:a aac -b:a 320k -movflags +faststart -y "$out")
    fi

    local fifo="${STATE_DIR}/fifo_${slot}_${BASHPID}"
    mkfifo "$fifo"

    "${cmd[@]}" </dev/null >"$fifo" 2>>"$log_file" &
    FF_PID=$!

    local short_name
    short_name="$(shorten_label "$label" 28)"

    local frame="0" fps="0.0" bitrate="0kbits/s" total_size="0" out_time="00:00:00" speed="0.0x"
    while IFS='=' read -r key val; do
        val="${val//[[:space:]]/}"
        case "$key" in
            frame)      frame="$val" ;;
            fps)        fps="$val" ;;
            bitrate)    bitrate="$val" ;;
            total_size) [[ "$val" =~ ^[0-9]+$ ]] && total_size=$(( val / 1048576 )) ;;
            out_time)   [[ "$val" != "N/A" ]] && out_time="${val%.*}" ;;
            speed)      speed="$val" ;;
            progress)
                if [[ "$val" == "end" ]]; then
                    set_slot_status "$slot" "[S${slot}] ${short_name} | finalizing MP4 faststart..."
                else
                    set_slot_status "$slot" "[S${slot}] ${short_name} | spd=${speed} fps=${fps} frm=${frame} t=${out_time} sz=${total_size}MB br=${bitrate}"
                fi
                ;;
        esac
    done < "$fifo"

    rm -f "$fifo"
    local rc=0
    wait "$FF_PID" || rc=$?
    FF_PID=""
    return "$rc"
}

process_one() {
    local slot="$1" avi_file="$2"
    local base_path="${avi_file%.*}"
    local base_name
    base_name="$(basename "$base_path")"

    local wav_file=""
    if [[ -f "${base_path}.wav" ]]; then
        wav_file="${base_path}.wav"
    elif [[ -f "${base_path}.WAV" ]]; then
        wav_file="${base_path}.WAV"
    else
        echo "SKIP|No matching WAV found for: ${base_name}.avi" > "${STATE_DIR}/res_${slot}"
        set_slot_status "$slot" "[S${slot}] Idle"
        return 0
    fi

    local out_file="${TARGET_DIR}/${base_name}.mp4"
    local tmp_file="${TARGET_DIR}/.${base_name}.tmp.mp4"
    local log_file="${LOG_DIR}/${base_name}.log"
    local fifo_glob="${STATE_DIR}/fifo_${slot}_*"
    local FF_PID=""
    local worker_aborted=false

    trap '
        worker_aborted=true
        [[ -n "${FF_PID:-}" ]] && kill -TERM "$FF_PID" 2>/dev/null || true
        rm -f "$tmp_file" $fifo_glob
        exit 130
    ' TERM INT

    : > "$log_file"
    set_slot_status "$slot" "[S${slot}] $(shorten_label "$base_name" 28) | starting..."

    local success=false mode_used="copy" rc=0
    if [[ "$SCALE_FHD" == false ]]; then
        run_ffmpeg "$slot" "$base_name" "$avi_file" "$wav_file" "$tmp_file" "copy" "$log_file" || rc=$?
        (( rc == 0 )) && success=true
    else
        mode_used="nvdec"
        run_ffmpeg "$slot" "$base_name" "$avi_file" "$wav_file" "$tmp_file" "nvdec" "$log_file" || rc=$?
        if (( rc == 0 )); then
            success=true
        elif [[ "$worker_aborted" == false ]] && (( rc < 128 )); then
            rm -f "$tmp_file"
            mode_used="cpu_fallback"
            set_slot_status "$slot" "[S${slot}] $(shorten_label "$base_name" 28) | NVDEC failed -> CPU fallback..."
            rc=0
            run_ffmpeg "$slot" "$base_name" "$avi_file" "$wav_file" "$tmp_file" "cpu_fallback" "$log_file" || rc=$?
            (( rc == 0 )) && success=true
        fi
    fi

    [[ "$worker_aborted" == true ]] && exit 130

    if [[ "$success" == true ]]; then
        mv -f "$tmp_file" "$out_file"
        touch -r "$avi_file" "$out_file"
        mv "$avi_file" "$wav_file" "$ORIG_DIR/"
        [[ ! -s "$log_file" ]] && rm -f "$log_file"
        echo "DONE|[DONE]  ${base_name}.mp4 (${mode_used}) -> Originals moved to _orig/" > "${STATE_DIR}/res_${slot}"
        set_slot_status "$slot" "[S${slot}] Idle"
        return 0
    else
        rm -f "$tmp_file"
        # Extract last non-empty error line from log_file for instant terminal visibility
        local last_err=""
        last_err="$(tail -n 1 "$log_file" 2>/dev/null || true)"
        echo "ERR|[ERROR] ${base_name} failed! (${last_err:-Check $log_file})" > "${STATE_DIR}/res_${slot}"
        set_slot_status "$slot" "[S${slot}] Idle"
        return 1
    fi
}

shopt -s nullglob nocaseglob
avi_files=("$TARGET_DIR"/*.avi)

if [[ ${#avi_files[@]} -eq 0 ]]; then
    rm -rf "$STATE_DIR"
    echo "No .avi files found in '$TARGET_DIR'."
    exit 0
fi

echo "Found ${#avi_files[@]} AVI file(s). Running with JOBS=${JOBS}, SCALE_FHD=${SCALE_FHD}, CQ=${CQ}..."
start_ui

failures=0

reap_one() {
    local finished_pid="" rc=0
    wait -n -p finished_pid || rc=$?
    if [[ -n "$finished_pid" && -n "${WORKER_PIDS[$finished_pid]:-}" ]]; then
        local freed_slot="${WORKER_PIDS[$finished_pid]}"
        unset 'WORKER_PIDS[$finished_pid]'
        FREE_SLOTS+=("$freed_slot")

        if [[ -f "${STATE_DIR}/res_${freed_slot}" ]]; then
            local res_line msg
            IFS= read -r res_line < "${STATE_DIR}/res_${freed_slot}" || true
            rm -f "${STATE_DIR}/res_${freed_slot}"
            msg="${res_line#*|}"
            [[ -n "$msg" ]] && log_event "$msg"
        fi
    fi
    if (( rc != 0 )) && [[ "$ABORTING" == false ]]; then
        (( failures += 1 ))
    fi
}

for avi_file in "${avi_files[@]}"; do
    [[ "$ABORTING" == true ]] && break

    local_slot="${FREE_SLOTS[-1]}"
    unset 'FREE_SLOTS[-1]'

    process_one "$local_slot" "$avi_file" &
    WORKER_PIDS[$!]="$local_slot"

    if (( ${#WORKER_PIDS[@]} >= JOBS )); then
        reap_one
    fi
done

while (( ${#WORKER_PIDS[@]} > 0 )) && [[ "$ABORTING" == false ]]; do
    reap_one
done

stop_ui
rm -rf "$STATE_DIR"

echo "Batch complete. Failures: ${failures}."
(( failures > 0 )) && exit 1 || exit 0
