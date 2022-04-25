#!/bin/bash -ue
#------------------------------------------------------------------------------
# Pre-requisite
#------------------------------------------------------------------------------
# https://wiki.archlinux.org/title/NVIDIA/Tips_and_tricks#Overclocking_and_cooling
# nvidia-xconfig --cool-bits=8

# https://github.com/NVIDIA/nvidia-settings/issues/65#issuecomment-832921061
# Add folliwng to /etc/X11/Xwrapper.config:
#     allowed_users=anybody
#     needs_root_rights=yes


#------------------------------------------------------------------------------
# GeForce RTX 2070
#------------------------------------------------------------------------------
gpu=0
level=4 # Up to 4 performance levels read from nvidia-settings's PowerMizer
core_offset=170 # 170MHz
mem_offset=2200 # 1100MHz
pl=200 # 200W

sudo nvidia-smi -pl $pl
nvidia-settings -a "[gpu:$gpu]/GPUGraphicsClockOffset[$level]=$core_offset"
nvidia-settings -a "[gpu:$gpu]/GPUMemoryTransferRateOffset[$level]=$mem_offset"
