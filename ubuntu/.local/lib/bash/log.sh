#!/usr/bin/env bash
#--------------------------------------------------------------------------------------------------
# log4bash - Makes logging in Bash scripting suck less
# Copyright (c) Fred Palmer
# Licensed under the MIT license
# http://github.com/fredpalmer/log4bash
#--------------------------------------------------------------------------------------------------
# Usage:
#    log, log_warning, log_success, log_error
#    log_captains (if having figlet)
#    # log_speak    (if having say, only on Mac)
#--------------------------------------------------------------------------------------------------

#--------------------------------------------------------------------------------------------------
# Begin Help Section

HELP_TEXT=""

# This function is called in the event of an error.
# Scripts which source this script may override by defining their own "usage" function
usage() {
    echo -e "${HELP_TEXT}";
    exit 1;
}

# End Help Section
#--------------------------------------------------------------------------------------------------

#--------------------------------------------------------------------------------------------------
# Begin Logging Section
declare -r LOG_DEFAULT_COLOR="\033[0m"
declare -r LOG_ERROR_COLOR="\033[1;31m"
declare -r LOG_INFO_COLOR="\033[1m"
declare -r LOG_SUCCESS_COLOR="\033[1;32m"
declare -r LOG_WARN_COLOR="\033[1;33m"
declare -r LOG_DEBUG_COLOR="\033[1;34m"

# This function scrubs the output of any control characters used in colorized output
# It's designed to be piped through with text that needs scrubbing.  The scrubbed
# text will come out the other side!
prepare_log_for_nonterminal() {
    # Essentially this strips all the control characters for log colors
    sed "s/[[:cntrl:]]\[[0-9;]*m//g"
}

log() {
    local log_text="$1"
	# Modified by Andy (Fix "set -u" not usable as log_level/log_color doesn't check argument existence)
	# Before
    # local log_level="$2"
    # local log_color="$3"
	# After
    local log_level
    local log_color
    [[ -z ${2-} ]] && log_level="INFO"              || log_level=$2
    [[ -z ${3-} ]] && log_color="${LOG_INFO_COLOR}" || log_color=$3
	# End of Andy

    # Default level to "info"
    [[ -z ${log_level} ]] && log_level="INFO";
    [[ -z ${log_color} ]] && log_color="${LOG_INFO_COLOR}";

    echo -e "${log_color}[$(date +"%Y-%m-%d %H:%M:%S %Z")] [${log_level}] ${log_text} ${LOG_DEFAULT_COLOR}";
    return 0;
}

log_info()      { log "$@"; }

log_speak()     {
	# Modified by Andy (Fix "set -u" not usable as log_level/log_color doesn't check argument existence)
	# Before
    # if type -P say >/dev/null
    # then
    #     local easier_to_say="$1";
    #     case "${easier_to_say}" in
    #         studionowdev*)
    #             easier_to_say="studio now dev ${easier_to_say#studionowdev}";
    #             ;;
    #         studionow*)
    #             easier_to_say="studio now ${easier_to_say#studionow}";
    #             ;;
    #     esac
    #     say "${easier_to_say}";
    # fi
	# After
    type -P say >/dev/null && say=say || say=spd-say
	local easier_to_say="$1";
	case "${easier_to_say}" in
		studionowdev*)
			easier_to_say="studio now dev ${easier_to_say#studionowdev}";
			;;
		studionow*)
			easier_to_say="studio now ${easier_to_say#studionow}";
			;;
	esac
	$say "${easier_to_say}";
	# End of Andy
    return 0;
}

log_success()   { log "$1" "SUCCESS" "${LOG_SUCCESS_COLOR}"; }
log_error()     { log "$1" "ERROR" "${LOG_ERROR_COLOR}"; log_speak "$1"; }
log_warning()   { log "$1" "WARNING" "${LOG_WARN_COLOR}"; }
log_debug()     { log "$1" "DEBUG" "${LOG_DEBUG_COLOR}"; }
log_captains()  {
    if type -P figlet >/dev/null;
    then
		# Modified by Andy (Remove font file and width specifications)
		# Before
        # figlet -f computer -w 120 "$1";
		# After
        figlet "$1";
		# End of Andy
    else
        log "$1";
    fi
    
    log_speak "$1";

    return 0;
}

log_campfire() {
    # This function performs a campfire notification with the arguments passed to it
    if [[ -z ${CAMPFIRE_API_AUTH_TOKEN} || -z ${CAMPFIRE_NOTIFICATION_URL} ]]
    then
        log_warning "CAMPFIRE_API_AUTH_TOKEN and CAMPFIRE_NOTIFICATION_URL must be set in order log to campfire."
        return 1;
    fi

    local campfire_message="
    {
        \"message\": {
            \"type\":\"TextMessage\",
            \"body\":\"$@\"
        }
    }"

    curl                                                            \
        --write-out "\r\n"                                          \
        --user ${CAMPFIRE_API_AUTH_TOKEN}:X                         \
        --header 'Content-Type: application/json'                   \
        --data "${campfire_message}"                                \
        ${CAMPFIRE_NOTIFICATION_URL}

    return $?;
}

# End Logging Section
#--------------------------------------------------------------------------------------------------

