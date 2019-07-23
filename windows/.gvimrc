set guioptions-=m  "remove menu bar
set guioptions-=T  "remove toolbar
set guioptions-=r  "remove right-hand scroll bar
set guioptions-=L  "remove left-hand scroll bar

if has('win32')
    set guifont=Consolas\ NF:h14
else
    set guifont=Consolas\ NF\ 16
endif


" Disable cursor blink
set guicursor+=a:blinkon0
