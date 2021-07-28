$z: fast change directory based on history usage rate
$zv: fast open file in vim based on history usage rate


```bash
#-------------------------------------------------------------------------------
#.zshrc
#-------------------------------------------------------------------------------
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
```
