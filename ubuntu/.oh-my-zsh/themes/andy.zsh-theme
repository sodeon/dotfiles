# NOTE: urxvt has limited emoji support. Thus, does not use emoji for error return prompt.

# If command success, no hint
local ret_status="%(?::%{$fg_bold[red]%}>_< )"
# local ret_status="%(?::%{$fg_bold[red]%}➜ )"
#local ret_status="%(?:%{$FG[247]%}➜ :%{$fg_bold[red]%}➜ )"

#PROMPT='
#${ret_status} %{$fg[cyan]%}%c%{$reset_color%} $(git_prompt_info)
#%{$fg[$CARETCOLOR]%}$%{$reset_color%} '
PROMPT='
${ret_status}%{$fg[yellow]%}%~%{$reset_color%}
%{$fg[$white]%}%{$reset_color%} '
#╭─${ret_status}%{$fg[yellow]%}%~%{$reset_color%}
#╰─%{$fg[$CARETCOLOR]%}%{$reset_color%}'
#PROMPT2='%{$fg[white]%}%{$reset_color%}'

# Move git branch to right
#RPROMPT='%{$FG[008]%}%*%{$reset_color%}'
# using FG[008] or any number color result in tab completion selection no white background (this bug only exists in ConEmu)
RPROMPT='%{$FG[008]%}$(git_current_branch)  %*%{$reset_color%}'
#RPROMPT='%{$fg[blue]%}$(git_current_branch)  %*%{$reset_color%}'

# git theming
#ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg_bold[blue]%}%{$fg[red]%}"
#ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg_bold[blue]%}%{$fg[blue]%}"
ZSH_THEME_GIT_PROMPT_PREFIX="%{$FG[008]%}%{$FG[008]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX=" %{$reset_color%} "
#ZSH_THEME_GIT_PROMPT_SUFFIX=",%{$reset_color%} "
#ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[blue]%} %{$fg[yellow]%}✗"
ZSH_THEME_GIT_PROMPT_DIRTY=""
ZSH_THEME_GIT_PROMPT_CLEAN=""
#ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[blue]%}"
#ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg[blue]%}"
#►▸
