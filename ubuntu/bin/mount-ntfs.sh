#!/bin/bash

if [ -b /dev/sda3 ]; then
	sudo mount /dev/sda3 /c
fi
if [ -b /dev/sda5 ]; then
	sudo mount /dev/sda5 /d
fi
if [ -b /dev/sdb2 ]; then
	sudo mount /dev/sdb2 /e
fi
