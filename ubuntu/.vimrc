" Reload vimrc: so ~/.vimrc
"-----------------------------------------------------------------------------
" VIM default config
"-----------------------------------------------------------------------------
set nocompatible
source $VIMRUNTIME/vimrc_example.vim
"source $VIMRUNTIME/mswin.vim
behave mswin

set shell=bash
set diffexpr=MyDiff()
function MyDiff()
  let opt = '-a --binary '
  if &diffopt =~ 'icase' | let opt = opt . '-i ' | endif
  if &diffopt =~ 'iwhite' | let opt = opt . '-b ' | endif
  let arg1 = v:fname_in
  if arg1 =~ ' ' | let arg1 = '"' . arg1 . '"' | endif
  let arg2 = v:fname_new
  if arg2 =~ ' ' | let arg2 = '"' . arg2 . '"' | endif
  let arg3 = v:fname_out
  if arg3 =~ ' ' | let arg3 = '"' . arg3 . '"' | endif
  let eq = ''
  if $VIMRUNTIME =~ ' '
    if &sh =~ '\<cmd'
      let cmd = '""' . $VIMRUNTIME . '\diff"'
      let eq = '"'
    else
      let cmd = substitute($VIMRUNTIME, ' ', '" ', '') . '\diff"'
    endif
  else
    let cmd = $VIMRUNTIME . '\diff'
  endif
  " Andy fix
  let cmd = "diff"
  " End of Andy fix
  silent execute '!' . cmd . ' ' . opt . arg1 . ' ' . arg2 . ' > ' . arg3 . eq
endfunction


"-----------------------------------------------------------------------------
" My config 
"-----------------------------------------------------------------------------
" Disable swap file (.swp)
set noswapfile

" Open files in write mode
" set noreadonly

"disable beep sound
set noeb vb t_vb=

set ignorecase

set nobackup
set ruler
set autoread

" Remove pesky *.un~ history file
set noundofile

"enable mouse for adjusting pane size
set ttymouse=xterm2
set mouse=a

" Directory browsing
"   Enter - open  
"   -     - go up directory
"   :Vexplorer - file explorer in vertical split
let g:netrw_banner=0        " disable annoying banner
let g:netrw_browse_split=4  " open in prior window
let g:netrw_altv=1          " open splits to the right
let g:netrw_liststyle=3     " tree view
let g:netrw_winsize=25      " size of 25%
" let g:netrw_list_hide=netrw_gitignore#Hide()
" let g:netrw_list_hide.=',\(^\|\s\s\)\zs\.\S\+'
command E  Vexplore
command Rr Vexplore

set splitbelow
set splitright

" Enable folding
set foldmethod=indent
set foldlevel=99

" By default, selection in vim will add one white space after the word
set selection=inclusive

let mapleader=','

" Change current working directory to the opened file
" To manually change directory to current file, use ":cd %:h"
autocmd BufEnter * silent! :lcd%:p:h


"-----------------------------------------------------------------------------
" Key bindings
"-----------------------------------------------------------------------------
nnoremap q    :q<CR>
" noremap <A-E> :q<CR> " not used since it conflicts with tmux
nnoremap ; :
nnoremap : ;
vnoremap ; :
vnoremap : ;
" swap pane same as tmux <c-w><c-o>
noremap <c-w><c-o> <c-w><c-r>
" horizontal -> vertical split
"noremap <c-w><c-v> <c-w>H
" vertical -> horizontal split
"noremap <c-w><c-s> <c-w>K

" go to the current/previous/next line's first non-white char (defualt: - and +)
" nnoremap _ -
" nnoremap - _

" Ctags
" set tags=./tags,./TAGS,tags;~,TAGS;~

" Use system clipboard when yanking (link yank register to system clipboard register "+")
set clipboard=unnamedplus

" System clipboard
" inoremap <C-v> <ESC>"+pa
" vnoremap <C-c> "+y
" noremap <Leader>y "+y
" noremap <Leader>p "+p

" Enable folding with the spacebar
nnoremap <space> za

" Insert line w/o entering insert mode
"    <S-Enter> doesn't work in terminal: https://stackoverflow.com/questions/16359878/vim-how-to-map-shift-enter)
nnoremap <S-Enter> O<Esc>
nnoremap <CR> o<Esc>

" copy till line end (like D means delete till line end)
noremap Y y$

" F12: run last command (like IDE run), terminal emit special key code for function key http://aperiodic.net/phil/archives/Geekery/term-function-keys.html
nnoremap <F12> :!<Up><CR>
nnoremap <Esc>[24~ :!<Up><CR>


"-----------------------------------------------------------------------------
" Looks
"-----------------------------------------------------------------------------
colorscheme torte
syntax enable

set nowrap
set number
hi LineNr guifg=#656565 ctermfg=darkgrey
" depp grey
"hi StatusLine ctermbg=8
set laststatus=0 " Remove status line

" cursor line
hi CursorLine cterm=NONE guibg=NONE
hi CursorLineNr ctermfg=grey guifg=grey
set cursorline

set shiftwidth=4
set tabstop=4
set expandtab
set autoindent		" Always set autoindenting on
autocmd FileType text setlocal textwidth=500 " Override vimrc_example.vim
set smartindent

" Disable newline insertion
set textwidth=500 wrapmargin=0
set tw=500

" Editor tabs, TabLineFill ctermbg must uses different color than ctermfg in order to take effect in urxvt
hi TabLineFill ctermfg=Black    ctermbg=White
hi TabLine     ctermfg=DarkGrey ctermbg=Black cterm=NONE
hi TabLineSel  ctermfg=White    ctermbg=DarkGrey
"hi Title ctermfg=LightBlue ctermbg=Black

" Set block cursor during insert mode
" Side effect: terminal cursor also changed after leaving vim
let &t_SI.="\e[6 q"
let &t_EI.="\e[1 q"
let &t_ti.="\e[1 q"
let &t_te.="\e[6 q"
" autocmd BufWinLeave * !echo -ne '\e[5 q'

" Cursor line (since cursor block blinking is enough, remove this)
" se cursorline
" hi CursorLineNr ctermfg=LightGrey
" hi clear CursorLine

" Invisible Vertical split
hi VertSplit ctermfg=Black ctermbg=DarkGrey
set fillchars+=vert:\ 


"-----------------------------------------------------------------------------
" Chinese character display
"-----------------------------------------------------------------------------
set encoding=utf-8
"set termencoding=utf-8
setglobal fileencoding=utf-8

" if has("unix")
"     set guifontwide=KaiTi\ 12
" elseif has("win32")
"     set guifontwide=NSimSun:h12
" endif


"-----------------------------------------------------------------------------
" vim-plug plugin manager
" Installation: curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
" :PlugInstall - installs plugins
"-----------------------------------------------------------------------------
set nocompatible " be iMproved, required
filetype off     " required

silent! call plug#begin('~/.vim/plug') " suppress error for machines not installing git

Plug 'vim-scripts/Align'
Plug 'vim-scripts/VisIncr'
Plug 'szw/vim-maximizer'
Plug 'AndrewRadev/switch.vim' "toggle boolean
Plug 'justinmk/vim-sneak' " motion search (type s plus two char to move cursor to first match, type : to go to next match)
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-surround' " change surround characters (
                          "     type cs'[ to change '' surrounding to [] surrounding
                          "     likewise, type ds to delete surrounding
                          "     type ysiw" to add double quote
                          "     type S in visual mode to add surround
Plug 'tpope/vim-repeat' " dot will repeat not only native command, but also plugin command
" Plug 'terryma/vim-multiple-cursors' "<C-n>, <C-p>, <C-x>, not used often enough
" Plug 'easymotion/vim-easymotion' # not like the idea that I have to look at the hint to know what to type
" Plug 'wincent/terminus' # correct cursor style in terminal (not working after exiting vim)
" Plug 'Valloric/YouCompleteMe'
" Plug 'mtth/scratch.vim'
" Plug 'majutsushi/tagbar'

" Searching (file, content, but not symbol)
Plug 'junegunn/fzf' " <C-p>
" Plug 'junegunn/fzf.vim' # more advanced fzf, with many more commands
Plug 'jremmen/vim-ripgrep' " :Rg (cannot bind ctrl-shift-f as vim cannot detect whether shift is pressed or not)

" syntax highlight
Plug 'posva/vim-vue',       {'for': 'vue'}
Plug 'digitaltoad/vim-pug', {'for': 'vue'}

" Not using, but other like these
" Plug 'tpope/vim-fugitive' " Git
" Plug 'Shougo/vimproc.vim' " interactive command line
" Plug 'vim-syntastic/syntastic' " error highlight in code
" Plug 'kien/ctrlp.vim' " yes, ctrl-p

call plug#end()


"-----------------------------------------------------------------------------
" Plugin settings
"
" NOTE:
" Cannot map <C-/>. See https://vimhelp.appspot.com/vim_faq.txt.html#faq-20.5
" Cannot use <C-e> as it will be hijacked by tmux
" Cannot use <C-[> as it is extremely slow for unknown reason
"-----------------------------------------------------------------------------
noremap <C-]> :Commentary<CR>
noremap <C-p> :FZF<CR>
noremap <C-e>z :MaximizerToggle<CR>
noremap <C-e>= :MaximizerToggle<CR>
noremap <C-w>z :MaximizerToggle<CR>
noremap <C-w>= :MaximizerToggle<CR>
" Toggle boolean
nnoremap t :Switch<CR>

" let g:sneak#s_next = 1
map : <Plug>Sneak_;

"-----------------------------------------------------------------------------
" Workarounds
"-----------------------------------------------------------------------------
" Do not add indentation when pasting from outside (for some reason, putting this in my config section won't work)
set paste

" If a VIM function that does not work in VSCode, then this function is probably not worth it

" hi Normal ctermfg=white
