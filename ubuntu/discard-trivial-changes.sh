#!/bin/bash
cd "$(dirname "$(realpath "$0")")"
git checkout ./.local/share/ranger/bookmarks
git checkout ./.config/hardware/*-displayrc.*
