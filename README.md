# Provision Ubuntu and Windows WSL
<!--- [![GitHub release](https://img.shields.io/github/release/sodeon/dotfiles.svg)](https://github.com/sodeon/dotfiles/releases) --->
![#f03c15](https://placehold.it/15/f03c15/000000?text=+) **This repo is not general enough for most without modifications.** ![#f03c15](https://placehold.it/15/f03c15/000000?text=+)
>If you are finding a more refined and complete experience, I would recommend [Luke Smith's github](https://github.com/LukeSmithxyz/).
>- [LARBS](https://github.com/LukeSmithxyz/LARBS): provision for Arch based linux
>- [voidrice](https://github.com/LukeSmithxyz/voidrice): configirations (rc, and etc)

## Purpose
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
