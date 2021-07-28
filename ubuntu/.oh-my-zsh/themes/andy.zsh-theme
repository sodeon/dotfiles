# NOTE: urxvt has limited emoji support. Thus, does not use emoji for error return prompt.

# If command success, no hint

local ret_status="%(?::%{$fg_bold[blue]%}😠 )"
# local ret_status="%(?::%{$fg_bold[red]%}➜ )"
#local ret_status="%(?:%{$FG[247]%}➜ :%{$fg_bold[red]%}➜ )"

# Draw line and update line size when terminal resizes
# https://unix.stackexchange.com/questions/360600/reload-zsh-when-resizing-terminator-window
# https://superuser.com/questions/845744/how-to-draw-a-line-between-commands-in-zsh-shell
drawline="${(r:$COLUMNS::─:)}"
TRAPWINCH() { drawline="${(r:$COLUMNS::─:)}" }

#PROMPT='
#${ret_status} %{$fg[cyan]%}%c%{$reset_color%} $(git_prompt_info)
#%{$fg[$CARETCOLOR]%}$%{$reset_color%} '
PROMPT='%{$FG[008]%}${drawline}%{$reset_color%}
${ret_status}%{$fg[yellow]%}%~%{$reset_color%}
%{$fg[white]%}%{$reset_color%} '
#╭─${ret_status}%{$fg[yellow]%}%~%{$reset_color%}
#╰─%{$fg[$CARETCOLOR]%}%{$reset_color%}'
#PROMPT2='%{$fg[white]%}%{$reset_color%}'

# Move git branch to right
#RPROMPT='%{$FG[008]%}%*%{$reset_color%}'
RPROMPT='%{$FG[008]%}$(git_prompt_info)  %*%{$reset_color%}'

# git theming
ZSH_THEME_GIT_PROMPT_PREFIX="%{$FG[008]%}"
#ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg_bold[blue]%}%{$fg[blue]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$FG[008]%}"
#ZSH_THEME_GIT_PROMPT_SUFFIX=",%{$reset_color%} "
ZSH_THEME_GIT_PROMPT_DIRTY=" %{$fg[yellow]%}U"
# ZSH_THEME_GIT_PROMPT_DIRTY=""
ZSH_THEME_GIT_PROMPT_CLEAN=""
#►▸
