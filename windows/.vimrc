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

" Do not add indentation when pasting from outside
set paste

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


"-----------------------------------------------------------------------------
" Key bindings
"-----------------------------------------------------------------------------
nnoremap q    :q<CR>
noremap <A-E> :q<CR>
noremap ; :
" swap pane same as tmux <c-w><c-o>
noremap <c-w><c-o> <c-w><c-r>
" horizontal -> vertical split
"noremap <c-w><c-v> <c-w>H
" vertical -> horizontal split
"noremap <c-w><c-s> <c-w>K

" Ctags
" set tags=./tags,./TAGS,tags;~,TAGS;~

" System clipboard
" inoremap <C-v> <ESC>"+pa
" vnoremap <C-c> "+y
" vnoremap <C-d> "+d


"-----------------------------------------------------------------------------
" Looks
"-----------------------------------------------------------------------------
set guifont=Consolas:h12
colorscheme torte
syntax enable

set nowrap
set number
hi LineNr guifg=#656565 ctermfg=darkgrey
" depp grey
"hi StatusLine ctermbg=8
set laststatus=0 " Remove status line

set expandtab
set shiftwidth=4
set tabstop=4
set autoindent		" Always set autoindenting on
autocmd FileType text setlocal textwidth=500 " Override vimrc_example.vim
set smartindent

" Disable newline insertion
set textwidth=500 wrapmargin=0
set tw=500

hi TabLineFill ctermfg=Black ctermbg=Black
hi TabLine ctermfg=DarkGrey ctermbg=Black cterm=NONE
hi TabLineSel ctermfg=White ctermbg=DarkGrey
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
" Vundle plugin manager
" Installation: git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim 
"
" Commands:
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"-----------------------------------------------------------------------------
set nocompatible              " be iMproved, required
filetype off                  " required

set rtp+=$HOME/.vim/bundle/Vundle.vim/
call vundle#begin('$HOME/.vim/bundle/')

Plugin 'VundleVim/Vundle.vim' "Required. Do not remove
Plugin 'vim-scripts/Align'
Plugin 'vim-scripts/VisIncr'
Plugin 'tpope/vim-commentary'
Plugin 'terryma/vim-multiple-cursors' "<C-n>, <C-p>, <C-x>
Plugin 'szw/vim-maximizer'
" Plugin 'wincent/terminus' # correct cursor style in terminal (not working after exiting vim)
" Plugin 'Valloric/YouCompleteMe'
" Plugin 'wincent/command-t' # never used
" Plugin 'mtth/scratch.vim'
" Plugin 'majutsushi/tagbar'

" Searching (file, content, but not symbol)
Plugin 'junegunn/fzf' " <C-p>
" Plugin 'junegunn/fzf.vim' # more advanced fzf, with many more commands
Plugin 'jremmen/vim-ripgrep' " :Rg (cannot bind ctrl-shift-f as vim cannot detect whether shift is pressed or not)
" Plugin 'francoiscabrol/ranger.vim'

" syntax highlight
Plugin 'posva/vim-vue'
Plugin 'digitaltoad/vim-pug'

" Not using, but other like these
" Plugin 'tpope/vim-fugitive' " Git
" Plugin 'Shougo/vimproc.vim' " interactive command line
" Plugin 'vim-syntastic/syntastic' " error highlight in code
" Plugin 'kien/ctrlp.vim' " yes, ctrl-p

call vundle#end()
filetype plugin indent on    " required


"-----------------------------------------------------------------------------
" Plugin settings
"
" NOTE:
" Cannot map <C-/>. See https://vimhelp.appspot.com/vim_faq.txt.html#faq-20.5
"-----------------------------------------------------------------------------
map <C-]> :Commentary<CR>j
map <C-p> :FZF<CR>
map <C-w>z :MaximizerToggle<CR>
