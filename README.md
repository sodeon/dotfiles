# Provision Ubuntu and Windows WSL
Provision/bootstrapping for Ubuntu and Windows WSL (Windows Subsystem for Linux), providing:

1. Install programs
2. Setup config
4. Config backup/restore utilities
3. Many keyboard bindings
5. Convenience scripts for hardware control and other simple jobs

>Package selection and configurations are highly **opinionate** with focus on **simplicity** and **vim style**. Some examples:
>- `i3` window manager
>- `ranger` file manager
>- `sxiv` `zathura` for image and pdf viewing

## Directory Structure
- `ubuntu`: backup/restore for Ubuntu
    - `apps`: apps not in apt package manager
	- `bin`: utilities written by me
    - `diff`: diff result between machine settings and this repo. To diff, run `diff.sh`
	- `.config` `.local` `.ohy-my-zsh` `.urxvt`: app config
- `windows`: backup/restore for Windows
	- `bin`: utilities written by me
    - `diff`: diff result between machine settings and this repo. To diff, run `diff.sh`
    - `Programs`: config used by native Windows programs, not WSL
	- `.config` `.ohy-my-zsh`: app config
- `usage`: cheat sheet for useful commands and tool usage
- `diff`: diff result between Ubuntu and Windows configuration. To diff, run `diff.sh`

## Installation (Provision)
1. Go to `ubuntu` or `windows` and run `provision.sh`
2. Go to `optional` directory to install tools you would like

## Config Backup/Restore
- `backup-dotfiles`: backup config
- `restore-dotfiles`: restore config

These two scripts can be found in `$HOME/bin` after provision.

## Keybindings
- Ubuntu: see `bin/activate-hotkeys` `bin/autohotkeys`, and `.config/i3/config`
- Windows: see `Programs/autohotkey.ahk`

## TODO
- Hasn't sync Ubuntu config to Windows for quite some time
- Run provision script on a newly setup machine
- More organized backup of desktop/laptop machine specific config
