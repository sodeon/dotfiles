#!/bin/bash
cd "$(dirname "$(realpath "$0")")"
git checkout ./.config/hardware/*-displayrc.*
git checkout ./.config/htop/htoprc
