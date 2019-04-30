# export PATH=$HOME/bin:/usr/local/bin:$PATH
export ZSH=~/.oh-my-zsh
export WINHOME=$(wslpath $(cmd.exe /C "echo %USERPROFILE%") | tr -d '\r')

# Set name of the theme to load. Optionally, if you set this to "random"
ZSH_THEME="andy"
#ZSH_THEME="robbyrussell" # default
#ZSH_THEME="agnoster"
#ZSH_THEME="avit"

# Setting this variable when ZSH_THEME=random cause zsh load theme from this variable instead of looking in ~/.oh-my-zsh/themes/
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Completion switch
# CASE_SENSITIVE="true"
HYPHEN_INSENSITIVE="true"

# oh-my-zsh auto-update
DISABLE_AUTO_UPDATE="true"
# export UPDATE_ZSH_DAYS=13

# Disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Command auto-correction.
ENABLE_CORRECTION="true"

# Display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# If you want to disable marking untracked files under VCS as dirty. This makes repository status check for large repositories much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# If you want to change the command execution time stamp shown in the history command output. The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"


#--------------------------------------------------------------------------------------------------------------
# Zsh (pre-oh-my-zsh) settings
#--------------------------------------------------------------------------------------------------------------
# Disable tab not found sound
unsetopt beep

# replace Ubuntu's ls color. This must put here so that oh-my-zsh will source the correct ls colors
#eval `dircolors ~/.DIR_COLORS`
LS_COLORS=$LS_COLORS:'ow=1;34:tw=1;34:' ; export LS_COLORS # win
# bold, yellow
export GREP_COLOR='1;33'


#--------------------------------------------------------------------------------------------------------------
# oh-my-Zsh
#--------------------------------------------------------------------------------------------------------------
plugins=(
  # file system
  pj
  jump

  # typing assist
  zsh-syntax-highlighting
  #compleat # hasn't tried, seems zsh already has such functions
  #zsh-autosuggestions
  #zsh-completions # there really isn't anything helpful (in ~/.oh-my-zsh/custom/plugins/zsh-completions/src)
  colored-man-pages

  # command helpers
  sudo
  #git # not really using these aliases. I use vscode or SourceTree
  #pip
  #supervisor

  # utilities
  calc
)
source $ZSH/oh-my-zsh.sh


#--------------------------------------------------------------------------------------------------------------
# Plugin settings
#--------------------------------------------------------------------------------------------------------------
# pj
PROJECT_PATHS=(/d/Work/code)

# syntax highlight
#ZSH_HIGHLIGHT_STYLES[path]=none
#ZSH_HIGHLIGHT_STYLES[path]=fg=008
#ZSH_HIGHLIGHT_STYLES[globbing]=fg=cyan

# Vim navigation keys in menu completion
zstyle ':completion:*' menu select
zmodload zsh/complist
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history

# colored cat (replace colorize plugin)
alias ccat='/bin/cat'
alias cat='pygmentize -g'

alias j='jump'


#--------------------------------------------------------------------------------------------------------------
# Aliases
#--------------------------------------------------------------------------------------------------------------
alias stats='zsh_stats'
alias lcd='jump' # for bash convention

newAndTouch() {touch $*; code $*          } 
duDepth()     {du --max-depth=$1 | sort -g}
alias d='vimdiff'
alias n='newAndTouch'
alias dud='duDepth'

# wsl helper
#source ~/.fzf/bin/util.zsh

# fzf (Fuzzy finder, auto-generated)
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
# bindkey '^P' fzf-file-widget # add ctrl-p as ctrl-t alternative. ConEmu/tmux already binds ctrl-t. ctrl-k will crash midnight commander
# vimFzf() {vim $(fzf --height 40%)}
bindkey '^P' fzf-file-widget
# fzf as filter for chmod...
# fzf pipe
alias add-quote="sed -e 's/^/\"/' | sed -e 's/$/\"/'"
alias fzfpipe="fzf $@ | add-quote | xargs"

# fasd
# eval "$(fasd --init auto)"
# eval "$(fasd --init zsh-hook zsh-ccomp zsh-ccomp-install zsh-wcomp zsh-wcomp-install posix-alias posix-hook)"
eval "$(fasd --init zsh-hook posix-hook)"
# Change directory by fasd
z() {
    local target
    target="$(fasd -Rdl "$1" | fzf -1 -0 --no-sort +m)" && cd "${target}" || return 1
}
# VIM by fasd
zv() { # does not support multiple files open yet
    local target
    target="$(fasd -Rfl "$1" | fzf -1 -0 --no-sort +m)" && vim -p "${target}" || return 1
}
# rg by fasd
# @param   $1        glob pattern passed to fasd
# @param   ${@:2}    arguments passed to rg
rz() {
    fasd -fl $1 | sed -e 's/^/"/' | sed -e 's/$/"/' | xargs rg "${@:2}"
}
# Fix error: 'permission denied ../../'
_fasd_preexec_fixed() {
  [[ -n $functions[fasd] ]] && unset -f fasd
}
add-zsh-hook preexec _fasd_preexec_fixed


#--------------------------------------------------------------------------------------------------------------
# Post oh-my-zsh settings
#--------------------------------------------------------------------------------------------------------------
# wsl-terminal use tmux automatically
[[ -z "$TMUX" && -n "$USE_TMUX" ]] && {
    [[ -n "$ATTACH_ONLY" ]] && {
        tmux a 2>/dev/null || { cd && exec tmux }
        exit
    }

    tmux new-window -c "$PWD" 2>/dev/null && exec tmux a
    exec tmux
}


#--------------------------------------------------------------------------------------------------------------
# Bash shared scripts
#--------------------------------------------------------------------------------------------------------------
source ~/.bashrc.zsh # This must be at the last line of .zshrc
