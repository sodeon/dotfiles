#!/bin/bash
#-----------------------------------------------------------------
# Diff the scripts and config between Ubuntu and Windows provision
#-----------------------------------------------------------------

diff ./ubuntu/provision.sh ./windows > ./diff/provision.sh.diff
diff ./ubuntu/backup.sh    ./windows > ./diff/backup.sh.diff
diff ./ubuntu/restore.sh   ./windows > ./diff/restore.sh.diff

diff ./ubuntu/.tmux.conf   ./windows > ./diff/.tmux.conf.diff
diff ./ubuntu/.vimrc       ./windows > ./diff/.vimrc.diff
diff ./ubuntu/.bashrc.zsh  ./windows > ./diff/.bashrc.zsh.diff
diff ./ubuntu/.zshrc       ./windows > ./diff/.zshrc.diff
