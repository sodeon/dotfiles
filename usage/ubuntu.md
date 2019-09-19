## As Root
- `sudo -i`

## Process management
- `pgrep`: find process ID by name
  - `-x`: exact match
- `pkill`: like pgrep but killing processes

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
- `color-picker`: [xcolor](https://github.com/Soft/xcolor)
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

## Performance tuning
[Reference](https://haydenjames.io/linux-performance-almost-always-add-swap-space/)
```bash
sudo cat /proc/sys/vm/swappiness # default: 60
sudo cat /proc/sys/vm/vfs_cache_pressure # default: 100
```

## Find
[Reference](https://www-howtogeek-com.cdn.ampproject.org/v/s/www.howtogeek.com/425408/how-to-use-all-linuxs-search-commands/amp/?amp_js_v=0.1#referrer=https%3A%2F%2Fwww.google.com&amp_tf=From%20%251%24s&ampshare=https%3A%2F%2Fwww.howtogeek.com%2F425408%2Fhow-to-use-all-linuxs-search-commands%2F)
- **`which -a`**: Searches $PATH executable
- **`whereis`**: Searches $PATH for executable, source and man
- **`apropos`**: Searches the man page with more fidelity than whatis (Meaning "related to").
- `whatis`: Searches the man one-line descriptions.
