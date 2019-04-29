#!/bin/bash
#-----------------------------------------------------------------
# Diff the scripts and config between current system and git repo
#-----------------------------------------------------------------

diff ~/.tmux.conf   . > ./diff/.tmux.conf.diff
diff ~/.vimrc       . > ./diff/.vimrc.diff
diff ~/.bashrc.zsh  . > ./diff/.bashrc.zsh.diff
diff ~/.zshrc       . > ./diff/.zshrc.diff
diff ~/.inputrc     . > ./diff/.inputrc.diff
