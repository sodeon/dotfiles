#!/bin/bash

if [ -b /dev/sda3 ]; then
	sudo mount /dev/sda3 /c
fi
if [ -b /dev/sda4 ]; then
	sudo mount /dev/sda4 /d
fi
