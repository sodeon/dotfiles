#!/bin/bash
#-----------------------------------------------------------------
# Diff the scripts and config between Ubuntu and Windows provision
#-----------------------------------------------------------------

diff ./ubuntu/provision.sh            ./windows > ./diff-ubuntu-windows/provision.sh.diff
diff ./ubuntu/backup.sh               ./windows > ./diff-ubuntu-windows/backup.sh.diff
diff ./ubuntu/restore.sh              ./windows > ./diff-ubuntu-windows/restore.sh.diff
diff ./ubuntu/post-provision-note.txt ./windows > ./diff-ubuntu-windows/post-provision-note.txt.diff

# Same config starting from v0.8.0. No longer need to diff
# diff ./ubuntu/.tmux.conf    ./windows > ./diff-ubuntu-windows/.tmux.conf.diff
# diff ./ubuntu/.vimrc        ./windows > ./diff-ubuntu-windows/.vimrc.diff
# diff ./ubuntu/.bash_aliases ./windows > ./diff-ubuntu-windows/.bash_aliases.diff
# diff ./ubuntu/.zshrc        ./windows > ./diff-ubuntu-windows/.zshrc.diff

tail -n +1 ./diff-ubuntu-windows/.*.diff
echo
tail -n +1 ./diff-ubuntu-windows/*.diff

