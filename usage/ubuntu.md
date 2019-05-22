## Process management
- `pgrep`: find process ID
- `pkill`: find process and kill it (just like pgrep except killing it)

## Network
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
