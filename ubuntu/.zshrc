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

# 10x increase .zsh_history size (default: 10000 lines)
export HISTSIZE=100000
export SAVEHIST=$HISTSIZE
setopt EXTENDED_HISTORY


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

# bold, yellow
export GREP_COLOR='1;33'


#--------------------------------------------------------------------------------------------------------------
# oh-my-Zsh
#--------------------------------------------------------------------------------------------------------------
plugins=(
  fancy-ctrl-z

  # Enable smart history search when for vi mode binding
  # history-substring-search

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
  # sudo
  sd # sd uses sd to replace sudo. sd allows alias to be recognized using sudo
  docker
  #pip
)
source $ZSH/oh-my-zsh.sh


#--------------------------------------------------------------------------------------------------------------
# Post oh-my-zsh settings
#--------------------------------------------------------------------------------------------------------------
PROJECT_PATHS=($HOME/code)


#--------------------------------------------------------------------------------------------------------------
# Aliases
#--------------------------------------------------------------------------------------------------------------
source ~/.bash_aliases

# zsh only aliases
alias j='jump'


#--------------------------------------------------------------------------------------------------------------
# Key bindings
#--------------------------------------------------------------------------------------------------------------
# Vim navigation keys in menu completion
zstyle ':completion:*' menu select
zmodload zsh/complist
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history

# Alt+,: Repeat last argument of current prompt
bindkey -s "^[," "!#\$^I"

# Make forward word behavior same as others (e.g. Chrome)
bindkey '^[[1;5C' emacs-forward-word
# Ctrl+backspace/delete to delete word
bindkey -M emacs '^H'    backward-kill-word
bindkey -M emacs '^[[3^' kill-word


#--------------------------------------------------------------------------------------------------------------
# External tools
#--------------------------------------------------------------------------------------------------------------
if [ -f ~/.fzf.zsh ]; then
    . ~/.fzf.zsh
    bindkey '^P' fzf-completion  # Ctrl-p for fzf completion
    bindkey '^I' ${fzf_default_completion:-expand-or-complete} # Restore default zsh tab key behavior
    # bindkey '\ed' fzf-cd-widget # alt-d: using fzf to change directory

    export FZF_DEFAULT_COMMAND='fdfind --hidden --type f --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_DEFAULT_OPTS='-1 --no-mouse --multi --color=16 --bind ctrl-a:select-all,ctrl-d:deselect-all,ctrl-f:page-down,ctrl-b:page-up'
    export FZF_COMPLETION_TRIGGER=''
fi

if [ -e $HOME/.nix-profile/etc/profile.d/nix.sh ]; then . $HOME/.nix-profile/etc/profile.d/nix.sh; fi # added by Nix installer

[ -f $HOME/.config/broot/launcher/bash/br ] && source $HOME/.config/broot/launcher/bash/br

return 0
