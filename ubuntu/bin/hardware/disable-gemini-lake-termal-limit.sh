#!/bin/bash -ue
busybox devmem 0xFED170A8 16 0000
busybox devmem 0xFED170AC 16 0000
wrmsr 0x610 0x0
