echo $PATH | grep -q "$HOME/.local/lib/bash" || export PATH=$HOME/.local/lib/bash:$PATH
echo $PATH | grep -q "$HOME/bin"             || export PATH=$HOME/bin:$PATH
export ZSH=~/.oh-my-zsh

# Set name of the theme to load. Optionally, if you set this to "random"
ZSH_THEME="andy"
# ZSH_THEME="robbyrussell" # default

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
# Pre-oh-my-zsh settings
#--------------------------------------------------------------------------------------------------------------
# Add pip executables (used by AWS)
export PATH=~/.local/bin:$PATH

# Defualt programs
export EDITOR='/usr/bin/vim'
export VIEWER='/usr/bin/vim'
export PAGER='/usr/bin/less'

unsetopt beep # Disable tab not found sound

# Overwrite cursor style so that vim cursor settings won't bleed to other tmux panes/windows
# 6: line, no blinking.  5: line, blinking.  2: block, no blinking. 1: block, blinking
echo -ne "\e[6 q"

stty -ixon # Disable c-s that freeze the terminal (it's a Linux behavior)

setopt +o nomatch # Avoid "'no match found' error when running find with * as part of pattern"

# replace Ubuntu's ls color. This must put here so that oh-my-zsh will source the correct ls colors
#eval `dircolors ~/.DIR_COLORS`
#LS_COLORS=$LS_COLORS:'ow=1;34:tw=1;34:' ; export LS_COLORS
# bold, yellow
export GREP_COLOR='1;33'


#--------------------------------------------------------------------------------------------------------------
# oh-my-Zsh
#--------------------------------------------------------------------------------------------------------------
plugins=(
  fancy-ctrl-z

  # File system
  pj
  jump

  # Typing assist
  zsh-syntax-highlighting
  #compleat # hasn't tried, seems zsh already has such functions
  #zsh-autosuggestions
  #zsh-completions # there really isn't anything helpful (in ~/.oh-my-zsh/custom/plugins/zsh-completions/src)
  colored-man-pages

  # Command helpers
  # NOTE: When adding new helper, remember to re-run $compinit and check ~/.zcompdump to see if the changes applied
  sudo
  docker
  #pip
)
source $ZSH/oh-my-zsh.sh


#--------------------------------------------------------------------------------------------------------------
# Plugin settings
#--------------------------------------------------------------------------------------------------------------
PROJECT_PATHS=($HOME/code)

# Vim navigation keys in menu completion
zstyle ':completion:*' menu select
zmodload zsh/complist
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history


#--------------------------------------------------------------------------------------------------------------
# Aliases
#--------------------------------------------------------------------------------------------------------------
source ~/.bash_aliases

# zsh aliases
alias j='jump'
alias stats='zsh_stats'

# fzf (Fuzzy finder, auto-generated)
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
bindkey '^P' fzf-completion  # Ctrl-p for fzf completion
bindkey '^I' ${fzf_default_completion:-expand-or-complete} # Tab key for default zsh completion
bindkey '\ed' fzf-cd-widget # alt-d: using fzf to change directory

# fasd
# eval "$(fasd --init auto)"
# eval "$(fasd --init zsh-hook zsh-ccomp zsh-ccomp-install zsh-wcomp zsh-wcomp-install posix-alias posix-hook)"
eval "$(fasd --init zsh-hook posix-hook)"
# Change directory by fasd
z() {
    local target
    target="$(fasd -Rdl "$@" | fzf -1 -0 --no-sort +m)" && cd "${target}" || return 1
}
alias z='nocorrect z'
# VIM by fasd
zv() { # does not support opening multiple files
    local target
    target="$(fasd -Rfl "$@" | fzf -1 -0 --no-sort +m)" && vim -p "${target}" || return 1
}
alias zv='nocorrect zv'
# rg by fasd
zr() {
    [ $# == 1 ] && fasd -fl    | sed -e 's/^/"/' | sed -e 's/$/"/' | xargs rg "${@:1}" \
                || fasd -fl $1 | sed -e 's/^/"/' | sed -e 's/$/"/' | xargs rg "${@:2}"
}
alias zr='nocorrect zr'
# Fix error: 'permission denied ../../'
_fasd_preexec_fixed() {
  [[ -n $functions[fasd] ]] && unset -f fasd
}
add-zsh-hook preexec _fasd_preexec_fixed


#--------------------------------------------------------------------------------------------------------------
# Post oh-my-zsh settings
#--------------------------------------------------------------------------------------------------------------
# Make forward word behavior same as others (e.g. Chrome)
bindkey '^[[1;5C' emacs-forward-word

# fzf
export FZF_DEFAULT_COMMAND='fdfind --hidden --type f --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_DEFAULT_OPTS='-1 --no-mouse --multi --color=16 --bind ctrl-a:select-all,ctrl-d:deselect-all,ctrl-f:page-down,ctrl-b:page-up'
export FZF_COMPLETION_TRIGGER=''

#
# VI mode
#
# bindkey -v # # Enable VI mode
# function zle-keymap-select zle-line-init { # Normal/insert mode aware cursor shape
#     if [ "$TERM" = "xterm-256color" ]; then
#         [ $KEYMAP = vicmd ] && echo -ne "\e[2 q" || echo -ne "\e[6 q"
#     fi
# }
# zle -N zle-keymap-select # Register zle-keymap-select, zle-line-init is registered somewhere else by oh-my-zsh
# export KEYTIMEOUT=1 # By default, exiting VI mode has 0.4sec delay
