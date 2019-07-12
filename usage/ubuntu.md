## As Root
- `sudo -i`

## Process management
- `pgrep`: find process ID
- `pkill`: find process and kill it

## Network
- `nm-applet`: network manager for WIFI connections
- `mtr`: not used as it is not compatible with WSL

## Build Debian Package From Github Repo
- Dependency: debhelper
- Build: under project root (one folder above "debian" folder)
	```sh
	dpkg-buildpackage -uc -us
	```
- Output: one folder above current folder (the ".." folder)

## Utilities
- `color-picker`: xcolor from https://github.com/Soft/xcolor
- Iso to USB flash: `sudo dd bs=4M if=file-name.iso of=/dev/sdc status=progress`

## Performance Analysis
- `htop`: needs no introduction
- `time`: summarize system usage
- `fincore`: check if file is cached in memory, usually combined with fdfind/find
- `nvidia-smi`: NVIDIA graphics card status summary. To continous monitor, `nvidia-smi dmon`
- `iostat -xtc 4 5`: show CPU/IO stat for 5 times with 4 sec interval between
- `mpstat -P ALL 4 5`: multi-processor stat show all cores with... (as above)
- `perf stat -a --sleep 10`: gather CPU insight stat for next 10sec (from linux-tools-generic package). **This tool is very powerful.**

## Chinese input
- 全形半形切換: ctrl + .
