" Reload vimrc: so ~/.vimrc
"-----------------------------------------------------------------------------
" VIM default config
"-----------------------------------------------------------------------------
set nocompatible
" source $VIMRUNTIME/vimrc_example.vim

set shell=bash


"-----------------------------------------------------------------------------
" Ported from vim_example.vim and defaults.vim in $VIMRUNTIME
"-----------------------------------------------------------------------------
set hlsearch
set history=200
set showcmd	" display incomplete commands
set wildmenu " display completion matches in a status line

set ttimeout " time out for key codes
set ttimeoutlen=0 " wait up to 0ms after Esc for special key (default: 100ms)

packadd! matchit

set display=truncate " Show @@@ in the last line if it is truncated.
" Show a few lines of context around the cursor.  Note that this makes the
" text scroll if you mouse-click near the start or end of the window.
set scrolloff=5
set incsearch
" Do not recognize octal numbers for Ctrl-A and Ctrl-X, most users find it confusing.
set nrformats-=octal

if has('win32')
  set guioptions-=t " For Win32 GUI: remove 't' flag from 'guioptions': no tearoff menu entries.
endif
let c_comment_strings=1 " I like highlighting strings inside C comments.

" When editing a file, always jump to the last known cursor position. Don't do it when the position is invalid, when inside an event handler
" (happens when dropping a file on gvim) and for a commit message (it's likely a different one than last time).
autocmd BufReadPost *
  \ if line("'\"") >= 1 && line("'\"") <= line("$") && &ft !~# 'commit'
  \ |   exe "normal! g`\""
  \ | endif

" Handy command to diff current file
if !exists(":DiffOrig")
  command DiffOrig vert new | set bt=nofile | r ++edit # | 0d_ | diffthis
		  \ | wincmd p | diffthis
endif


"-----------------------------------------------------------------------------
" Looks
"-----------------------------------------------------------------------------
colorscheme torte
syntax on

set nowrap
set number
hi LineNr guifg=#656565 ctermfg=darkgrey
" depp grey
"hi StatusLine ctermbg=8
set laststatus=0 " Remove status line

set encoding=utf-8
"set termencoding=utf-8
setglobal fileencoding=utf-8

" cursor line
hi CursorLine cterm=NONE guibg=NONE
hi CursorLineNr ctermfg=grey guifg=grey
set cursorline

set tabstop=4
set softtabstop=4
set shiftwidth=4
set smarttab
set expandtab
set autoindent " Always set autoindenting on
" set cindent " smarter than 'smartindent' but has side effect on non C like programming languages. TODO: Use autocmd to  enable cindent when opening C like languages
autocmd FileType text setlocal textwidth=500 " Override vimrc_example.vim

" Disable newline insertion
set textwidth=500 wrapmargin=0
set tw=500

" Editor tabs, TabLineFill ctermbg must uses different color than ctermfg in order to take effect in urxvt
hi TabLineFill ctermfg=Black    ctermbg=White
hi TabLine     ctermfg=DarkGrey ctermbg=Black cterm=NONE
hi TabLineSel  ctermfg=White    ctermbg=DarkGrey
"hi Title ctermfg=LightBlue ctermbg=Black

" Set block cursor during insert mode
" https://vim.fandom.com/wiki/Change_cursor_shape_in_different_modes
let &t_SI.="\e[6 q"
let &t_EI.="\e[2 q"
let &t_ti.="\e[2 q"
let &t_te.="\e[6 q"

" Cursor line (since cursor block blinking is enough, remove this)
" se cursorline
" hi CursorLineNr ctermfg=LightGrey
" hi clear CursorLine

" Invisible Vertical split
hi VertSplit ctermfg=Black ctermbg=DarkGrey
set fillchars+=vert:\ 


"-----------------------------------------------------------------------------
" Commands
"-----------------------------------------------------------------------------
" Change current working directory to the opened file
command! Cd :cd %:h

" Set VIM as server for outside to send command in
" Use case: Press ctrl-z to go to zsh and open files (by tabnew bash alias) to edit
function! Serve(...)
    if (a:0 == 0)
        let serverName = "VIM"
    else
        let serverName = a:1
    endif
    call remote_startserver(serverName)
endfunction
command! -nargs=? Serve call Serve()

" Open file in VSCode
command! OpenInVSCode exe "silent !code --goto '" . expand("%") . ":" . line(".") . ":" . col(".") . "'" | redraw!


"-----------------------------------------------------------------------------
" My config 
"-----------------------------------------------------------------------------
" Disable swap file (.swp), backup file, and *.un~ history file
set noswapfile
set nobackup
set noundofile

" Disable beep sound
set noeb vb t_vb=

set ignorecase
set wildignorecase " Ignore case in path completion

set ruler

" When file is changed externally, show notifications. This functionality is broken, use vim-autoread plugin instead.
set autoread
" autocmd BufEnter,FocusGained <buffer> checktime " Workaround, but not good enough. FocusGained only works in gvim.

" Enable mouse for adjusting pane size
set ttymouse=xterm2
set mouse=a

set splitbelow
set splitright

" Enable folding
set foldmethod=indent
set foldlevel=99

" By default, selection in vim will add one white space after the word
set selection=inclusive

" Use system clipboard when yanking (link yank register to system clipboard register "+")
" https://stackoverflow.com/questions/6453595/prevent-vim-from-clearing-the-clipboard-on-exit
set clipboard=unnamedplus
if executable("xsel") " By default, VIM will clear clipboard after closing or switched to background
    function! PreserveClipboard()
        call system("xsel -ib", getreg('+'))
    endfunction
  
    function! PreserveClipboadAndSuspend()
        call PreserveClipboard()
        suspend
    endfunction
  
    autocmd VimLeave * call PreserveClipboard()
    nnoremap <silent> <c-z> :call PreserveClipboadAndSuspend()<cr>
    vnoremap <silent> <c-z> :<c-u>call PreserveClipboadAndSuspend()<cr>
endif

" Directory browsing
"   Enter - open  
"   -     - go up directory
"   :Vexplorer - file explorer in vertical split
let g:netrw_banner=0        " disable annoying banner
let g:netrw_browse_split=0  " open in current window
let g:netrw_altv=1          " open splits to the right
let g:netrw_liststyle=3     " tree view
let g:netrw_winsize=25      " size of 25%
command! E  Vexplore


"-----------------------------------------------------------------------------
" Key bindings
" NOTE: Vim doeesn't recognize hyper key)
"-----------------------------------------------------------------------------
let mapleader=','

nnoremap <silent> q :q<CR>
nnoremap <silent> Q :qa<CR>
nnoremap ; :
nnoremap : ;
vnoremap ; :
vnoremap : ;

" Copy till line end (like D means delete till line end)
noremap Y y$
" Paste at the end of the line
" noremap P $a<Space><Esc>p

" Enable folding with the spacebar
nnoremap <space> za

" Insert line w/o entering insert mode. (Shift+Enter doesn't work in terminal)
nnoremap <S-Enter> O<Esc>
nnoremap <CR>      o<Esc>

" F12: run last command (like IDE run), terminal emit special key code for function key http://aperiodic.net/phil/archives/Geekery/term-function-keys.html
nnoremap <F12> :!<Up><CR>
nnoremap <Esc>[24~ :!<Up><CR>

" Split resize and movement
" NOTE: To move split in complext layout, move vertical direction first (jk), then move horizontal direction (hl)
nnoremap <silent> <C-w>t :Tabmerge right<CR>
" Move split to new tab: <C-w>T
" Move split <C-w> H/J/K/L (left/bottom/top/right)

" Tab switching
" NOTE: Terminal does not send alt key, insteand send escape key. Therefore, vim won't see alt key but escape key
"       https://stackoverflow.com/questions/6778961/alt-key-shortcuts-not-working-on-gnome-terminal-with-vim
if has('gui_running')
	nnoremap          <M-q> gT
	nnoremap          <M-e> gt
	nnoremap <silent> <M-e> :q<CR>
    nnoremap <silent> <M-S-q> :-tabmove<CR>
    nnoremap <silent> <M-S-w> :+tabmove<CR>
else
	nnoremap          <Esc>q gT
	nnoremap          <Esc>w gt
	nnoremap <silent> <Esc>e :q<CR>
    nnoremap <silent> <Esc><S-q> :-tabmove<CR>
    nnoremap <silent> <Esc><S-w> :+tabmove<CR>
endif

" Make ctrl+left/right same behavior across all applications
nnoremap <C-Right> E
vnoremap <C-Right> E

" Copy/paste without using system clipboard (using vim built-in register)
nnoremap <leader>y "pyy
nnoremap <leader>p "pp
vnoremap <leader>y "py
vnoremap <leader>p "pp

" Fix ctrl+left/right not working with urxvt+tmux
map <ESC>[1;5D <C-Left>
map <ESC>[1;5C <C-Right>


"-----------------------------------------------------------------------------
" vim-plug plugin manager
" Installation: curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
" :PlugInstall - installs plugins
"-----------------------------------------------------------------------------
filetype off " required
silent! call plug#begin('~/.vim/plug') " Suppress error for machines not installing git

Plug 'vim-scripts/Align' " :AlignCtrl =lp1P1I
                         "     which means:
                         "     p1 pad one space before each separator. P1 pad one space after each separator
                         "     I  preserve and apply the first line's leading white space to all Align'd lines
                         "     l fields will be left-justified
                         "     = all separators are equivalent
Plug 'vim-scripts/VisIncr'
Plug 'vim-scripts/Tabmerge'
Plug 'szw/vim-maximizer'
Plug 'AndrewRadev/switch.vim' " Toggle boolean and can be more
Plug 'justinmk/vim-sneak' " Motion search (type s plus two char to move cursor to first match, type : to go to next match)
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-surround' " Change surround characters:
                          "     Type cs'[ to change '' surrounding to [] surrounding
                          "     Likewise, type ds to delete surrounding
                          "     Type S in visual mode to add surround
Plug 'tpope/vim-repeat' " dot will repeat not only native command, but also plugin command
Plug 'will133/vim-dirdiff'
Plug 'thaerkh/vim-workspace' " Provides better session experiences. It behaves like modern IDE. To enable workspace: ':ToggleWorkspace'
Plug 'sodeon/vim-i3-integration'
" Plug 'Valloric/YouCompleteMe'
" Plug 'mtth/scratch.vim'
" Plug 'majutsushi/tagbar'

" Searching (file, content, but not symbol)
Plug 'sodeon/fzf' " <C-p>  use <C-t>/<C-v> for new tab/split
Plug 'jremmen/vim-ripgrep' " :Rg (cannot bind ctrl-shift-f as vim cannot detect whether shift is pressed or not)

" File type plugins
Plug 'posva/vim-vue',                {'for': 'vue'}
Plug 'digitaltoad/vim-pug',          {'for': 'vue'}
Plug 'iamcco/markdown-preview.nvim', {'do': { -> mkdp#util#install() }} " Cannot add {'for': 'markdown'}. 
                                                                        " With it, PlugInstall must run with a markdown file opened.
                                                                        " Or post install 'do' will fail.

" Not using, but other like these
" Plug 'tpope/vim-fugitive' " Git
" Plug 'Shougo/vimproc.vim' " Interactive command line
" Plug 'vim-syntastic/syntastic' " Error highlight in code
" Plug 'kien/ctrlp.vim' " Yes, ctrl-p

call plug#end()


"-----------------------------------------------------------------------------
" Plugin settings
"
" NOTE:
" Cannot map <C-/>. See https://vimhelp.appspot.com/vim_faq.txt.html#faq-20.5
" Cannot use <C-e>: hijacked by tmux
" Cannot use <C-[>: extremely slow for unknown reason
"-----------------------------------------------------------------------------
noremap ga :Align 
noremap gA :AlignCtrl 

noremap  <silent> <C-]> :Commentary<CR>
noremap  <silent> <C-p> :FZF<CR>
noremap  <silent> <C-w>z :MaximizerToggle<CR>
nnoremap <silent> t :Switch<CR>

" let g:sneak#s_next = 1
map <silent> : <Plug>Sneak_;

" Session management
let g:workspace_session_name = '.session.vim'
let g:workspace_session_directory = $HOME.'/.vim/sessions/'
let g:workspace_persist_undo_history = 0  " Do not keep undo history
let g:workspace_autosave = 0
let g:workspace_session_disable_on_args = 1 " Only workspace when not opening files (open vim only)

" Switcher
let g:switch_custom_definitions =
    \ [
    \   ['enable', 'disable'],
    \   ['Enable', 'Disable'],
    \   ['yes'   , 'no'     ],
    \   ['on'    , 'off'    ],
    \   ['and'   , 'or'     ],
    \   ['||'    , '&&'     ]
    \ ]

" Commentary
au FileType xdefaults       setlocal commentstring=!\ %s
au FileType markdown        setlocal commentstring=<!--\ %s\ -->
au BufNewFile,BufRead *.txt setlocal commentstring=#\ %s

" Markdown preview (by default, this plugin does not open browser in new window)
function! g:OpenBrowser(url)
    silent exe '!google-chrome --new-window ' . a:url
endfunction
let g:mkdp_browserfunc = 'g:OpenBrowser'
let g:mkdp_auto_close = 0 " If auto-close, switching between buffer/split/tab will close preview

" Window navigation/resizing/movement
if has('gui_running') " gvim can see alt key
	nnoremap <silent> <M-l>   :call Focus('right')<CR>
    nnoremap <silent> <M-h>   :call Focus('left' )<CR>
	nnoremap <silent> <M-k>   :call Focus('up'   )<CR>
	nnoremap <silent> <M-j>   :call Focus('down' )<CR>
	nnoremap <silent> <M-L>   :call Move('right')<CR>
	nnoremap <silent> <M-H>   :call Move('left' )<CR>
	nnoremap <silent> <M-K>   :call Move('up'   )<CR>
	nnoremap <silent> <M-J>   :call Move('down' )<CR>
	nnoremap <silent> <C-M-l> :call Resize('horizontal',  10)<CR>
	nnoremap <silent> <C-M-h> :call Resize('horizontal', -10)<CR>
	nnoremap <silent> <C-M-k> :call Resize('vertical'  ,  6 )<CR>
	nnoremap <silent> <C-M-j> :call Resize('vertical'  , -6 )<CR>
else " alt key is sent as <Esc>
	nnoremap <silent> <Esc>l     :call Focus('right')<CR>
    nnoremap <silent> <Esc>h     :call Focus('left' )<CR>
	nnoremap <silent> <Esc>k     :call Focus('up'   )<CR>
	nnoremap <silent> <Esc>j     :call Focus('down' )<CR>
	nnoremap <silent> <Esc>L     :call Move('right')<CR> 
	nnoremap <silent> <Esc>H     :call Move('left' )<CR>
	nnoremap <silent> <Esc>K     :call Move('up'   )<CR>
	nnoremap <silent> <Esc>J     :call Move('down' )<CR>
	nnoremap <silent> <Esc><C-l> :call Resize('horizontal',  10)<CR>
	nnoremap <silent> <Esc><C-h> :call Resize('horizontal', -10)<CR>
	nnoremap <silent> <Esc><C-k> :call Resize('vertical'  ,  6 )<CR>
	nnoremap <silent> <Esc><C-j> :call Resize('vertical'  , -6 )<CR>
endif

" fzf
let g:fzf_open_action = 'tab split'

" Z - cd to recent / frequent directories (fasd) https://github.com/clvv/fasd/wiki/Vim-Integration
command! -nargs=* Z :call Z(<f-args>)
function! Z(...)
  let cmd = 'fasd -d -e printf'
  for arg in a:000
    let cmd = cmd . ' ' . arg
  endfor
  let path = system(cmd)
  if isdirectory(path)
    echo path
    exec 'cd' fnameescape(path)
  endif
endfunction


"-----------------------------------------------------------------------------
" Gotchas
"-----------------------------------------------------------------------------
" When pasting block of code from outside apps, execute ":set paste" before paste and ":set nopaste" after paste.
" Why: VIM in terminal cannot distinguish text from paste or keyboard input.
"      If not, there will be unwanted white spaces added for each indented line.
"      ":set paste" will override expandtab to noexpandtab, autoindent to noautoindent. Therefore, we do not add ":set paste" to .vimrc
