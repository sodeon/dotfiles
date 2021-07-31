#!/bin/bash -ue
# sudo apt install devmem2 msr-tools
# sudo chmod u+s /usr/bin/devmem2
# sudo chmod u+s /usr/sbin/wrmsr

disable() {
    devmem2 0xFED170A8 h 0000 > /dev/null
    devmem2 0xFED170AC h 0000 > /dev/null
    wrmsr 0x610 0x0
    echo "Remove TDP limit with unlimited values."
}

enable() {
    devmem2 0xFED170A8 h 0x8A00 > /dev/null
    devmem2 0xFED170AC h 0x9900 > /dev/null
    wrmsr 0x610 48 0x9900001b8a00
    echo "Enable TDP limit with default values."
}

toggle() {
    [[ `devmem2 0xFED170A8 h | grep Value | sed 's/^.*:\s*//'` == 0x8A00 ]] && disable || enable
}

[ -z ${1-} ] && toggle || $1




#------------------------------------------------------------------------------
# Legacy
#------------------------------------------------------------------------------
# busybox devmem 0xFED170A8 16 0x8A00
# busybox devmem 0xFED170AC 16 0x9900
# [[ `sudo busybox devmem 0xFED170A8 16` == "0x8A00" ]] && disable || enable
