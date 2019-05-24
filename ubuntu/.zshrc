export PATH=/usr/local/bin:$PATH
# export PATH=$HOME/bin:/usr/local/bin:$HOME/.local/lib/bash:$PATH
export ZSH=~/.oh-my-zsh

# Set name of the theme to load. Optionally, if you set this to "random"
ZSH_THEME="andy"
#ZSH_THEME="robbyrussell" # default

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
# add pip executables (used by AWS)
export PATH=~/.local/bin:$PATH

# Disable tab not found sound
unsetopt beep

# replace Ubuntu's ls color. This must put here so that oh-my-zsh will source the correct ls colors
#eval `dircolors ~/.DIR_COLORS`
#LS_COLORS=$LS_COLORS:'ow=1;34:tw=1;34:' ; export LS_COLORS
# bold, yellow
export GREP_COLOR='1;33'

# Avoid "'no match found' error when running find with * as part of pattern"
setopt +o nomatch


#--------------------------------------------------------------------------------------------------------------
# oh-my-Zsh
#--------------------------------------------------------------------------------------------------------------
plugins=(
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
  #git
  #pip
  #supervisor

  # utilities
  # calc
)
source $ZSH/oh-my-zsh.sh


#--------------------------------------------------------------------------------------------------------------
# Plugin settings
#--------------------------------------------------------------------------------------------------------------
# pj
PROJECT_PATHS=($HOME/code)

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
# alias ccat='/bin/cat'
# alias cat='pygmentize -g'

alias j='jump'


#--------------------------------------------------------------------------------------------------------------
# Aliases
#--------------------------------------------------------------------------------------------------------------
alias stats='zsh_stats'

newAndTouch() {touch $*; code $*          } 
duDepth()     {du --max-depth=$1 | sort -g}
alias d='vimdiff'
alias n='newAndTouch'
alias dud='duDepth'

# wsl helper
#source ~/.fzf/bin/util.zsh

# fzf (Fuzzy finder, auto-generated)
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
bindkey '^P' fzf-completion  # Ctrl-p for fzf completion
bindkey '^I' ${fzf_default_completion:-expand-or-complete} # Tab key for default zsh completion

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
zv() { # does not support multiple files open yet
    local target
    target="$(fasd -Rfl "$@" | fzf -1 -0 --no-sort +m)" && vim -p "${target}" || return 1
}
alias zv='nocorrect zv'
# rg by fasd
# @param   $1        glob pattern passed to fasd
# @param   ${@:2}    arguments passed to rg
zr() {
    fasd -fl $1 | sed -e 's/^/"/' | sed -e 's/$/"/' | xargs rg "${@:2}"
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
source ~/.bash_aliases
source ~/.bashrc.zsh # This must be at the last line of .zshrc
export FZF_COMPLETION_TRIGGER='' # Do not move this to bashrc.zsh. To do this, we also must assign "tab" to bash default completion.
