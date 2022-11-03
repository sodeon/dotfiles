#!/bin/bash

# @return script's directory
cur_dir() { echo $(dirname "$(realpath "$0")"); }

# @return change directory to script's directory
cd_cur_dir() { cd $(dirname "$(realpath "$0")"); }

# Check if array has element (https://stackoverflow.com/questions/3685970/check-if-a-bash-array-contains-a-value)
has () {
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}

