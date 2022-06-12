set guioptions-=m  "remove menu bar
set guioptions-=T  "remove toolbar
set guioptions-=r  "remove right-hand scroll bar
set guioptions-=L  "remove left-hand scroll bar

if has('win32')
    set guifont=Consolas\ NF:h14
else
    set guifont=FiraCode\ Nerd\ Font\ Mono\ Light\ 14
endif

" Disable cursor blink
set guicursor+=a:blinkon0

" Font ligatures
set guiligatures=!\"$%&\'()*+,-./:;<=>?@[\\]^_`{\|}~
" set guiligatures=!\"$%&\'()*+,-./:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{\|}~
