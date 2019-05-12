#!/bin/bash

# @return script's directory
cur_dir() {
	echo $(dirname "$(realpath "$0")")
}
