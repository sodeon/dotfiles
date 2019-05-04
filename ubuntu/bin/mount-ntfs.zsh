#!/bin/zsh

source ~/.config/hardware/ntfs-drives.zsh

for src dst in ${(kv)ntfsMap}; do
    sudo mount $src $dst
done
