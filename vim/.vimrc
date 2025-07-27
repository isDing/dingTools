" *************************************************************************
" presettings
" Source project address: https://github.com/NewComer00/my-vimrc
" *************************************************************************

" ASCII art -- https://patorjk.com/software/taag/#p=display&f=Small&t=MY-VIMRC
let MY_VIMRC_WELCOME = "\n"
            \ .' __  ____   __ __   _____ __  __ ___  ___ '."\n"
            \ .'|  \/  \ \ / /_\ \ / /_ _|  \/  | _ \/ __|'."\n"
            \ .'| |\/| |\ V /___\ V / | || |\/| |   / (__ '."\n"
            \ .'|_|  |_| |_|     \_/ |___|_|  |_|_|_\\___|'."\n"

" vim data directory
if has('win32')
    let DATA_DIR = expand($HOME.'/vimfiles')
else
    let DATA_DIR = expand($HOME.'/.vim')
endif

" only use basic functions of my-vimrc -- 1:true 0:false
let MY_VIMRC_BASIC = 0

" mirrors for github site & github raw
let GITHUB_SITE = 'https://github.com/'
" github 无法访问时，使用下面的克隆地址 https://docs.suanlix.cn/github.html
" let GITHUB_SITE = 'https://gh.llkk.cc/https://github.com/'
let GITHUB_RAW = 'https://raw.githubusercontent.com/'

" *************************************************************************
" basic settings
" *************************************************************************

set encoding=utf8
" 设置不兼容Vi
set nocompatible

" 如果支持终端真彩色 termguicolors 则启用。
if has('termguicolors')
    set termguicolors
endif
" 确保在tmux中正确显示
if exists('+termguicolors') && $TERM == 'tmux-256color'
  let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
  let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
  set termguicolors
endif


" 优化滚动性能
" speed up vim scrolling
" https://stackoverflow.com/questions/307148/vim-scrolling-slowly
set ttyfast
set lazyredraw

" 优化正则表达式引擎性能
" speed up syntax highlighting & regex performance
" https://vi.stackexchange.com/a/21641
" https://gist.github.com/glts/5646749
if exists('&regexpengine')
  set regexpengine=1
endif

" 允许退格键删除缩进、换行等
" to enable backspace key
" https://vi.stackexchange.com/a/2163
set backspace=indent,eol,start

" 关闭可视响铃
set novisualbell

" 修复Windows终端替换模式问题
" to deal with REPLACE MODE problem on windows cmd or windows terminal
" https://superuser.com/a/1525060
set t_u7=

" 设置256色, 并开启语法高亮
set t_Co=256
syntax on

" 高亮搜索hlsearch、增量搜索incsearch、忽略大小写ignorecase但智能大小写smartcase
set hlsearch
set incsearch
set ignorecase
set smartcase

" 显示行号、相对行号
set number
set relativenumber

" 不自动换行
set nowrap

" 高亮光标行
set cursorline

" 缩进设置
" 制表符宽度、缩进宽度、使用空格代替制表符、自动缩进
set tabstop=4
set shiftwidth=4
set expandtab
set autoindent

" 命令行补全模式
set wildmode=longest,full
set wildmenu

set mouse=a
" mouse will still work beyond the 223rd col if vim supports mouse-sgr
" https://stackoverflow.com/a/19253251/15283141
if has("mouse_sgr")
    set ttymouse=sgr
else
    set ttymouse=xterm2
end

" 始终显示状态栏和命令栏
set laststatus=2

" 新分割窗口出现在下方和右侧
set splitbelow
set splitright

" 设置字典和补全选项
set dictionary+=/usr/share/dict/words
set complete+=k

" 设置可见的特殊字符, 默认关闭
" to be compatable with older version
" https://stackoverflow.com/a/36374234/15283141
if has("patch-7.4.710")
    set listchars=eol:↵,tab:\|\|,trail:~,extends:>,precedes:<,space:·
else
    set listchars=eol:↵,tab:\|\|,trail:~,extends:>,precedes:<
endif
" set list

" 设置持久撤销undofile, 并创建撤销文件目录
" Let's save undo info!
" from https://vi.stackexchange.com/a/53
" let s:undo_dir = expand(DATA_DIR.'/undo-dir')
" if !isdirectory(s:undo_dir)
"     call mkdir(s:undo_dir, "p", 0700)
" endif
" let &undodir = s:undo_dir
" set undofile

" 设置标签文件 tags 的搜索路径
" search tags file recursively
" https://stackoverflow.com/a/5019111/15283141
set tags=./tags,./TAGS,tags;~,TAGS;~

" *************************************************************************
" basic functions
" *************************************************************************

" a wrapper of input() but without the retval
function! s:ShowDialog(text)
    if !has('gui_running')
        "TODO: a trick only to keep the text shown on win32
        if has('win32')
            new | redraw | quit
            echo "\n"
        endif
        call input(a:text)
    else
        call inputdialog(a:text)
    endif
endfunction

" verify the first maxline of the downloaded file with the pattern
" retval: 0 -- good;
"        -1 -- file not readable;
"        -2 -- pattern not found in the first maxline of file
function! s:VerifyDownload(filename, pattern, maxline)
    if !filereadable(a:filename)
        echo '[my-vimrc] Download failed. "'.a:filename.'" is not found or not readable.'
        return -1
    endif

    let lines = readfile(a:filename)
    let line_count = len(lines)
    let i = 0
    while i < line_count && i < a:maxline
        if lines[i] =~ a:pattern
            return 0
        endif
        let i += 1
    endwhile
    echo '[my-vimrc] Verification failed. "'.a:filename.'" might be corrupted.'
    return -2
endfunction

" function to run a shell
" https://stackoverflow.com/questions/1236563/how-do-i-run-a-terminal-inside-of-vim
function! OpenShell()
    if v:version < 801
        echo "Press any key to open a shell..."
        echo "After the shell opened, press <C-d> or type 'exit' to quit the shell."
        call getchar()
        sh
    else
        bo 10sp | term ++curwin

        " enable the shortcut to close the shell
        if has('win32')
            tnoremap <silent> <F3> <C-End><C-Home>exit<CR>
        else
            tnoremap <silent> <F3> <C-a><C-k><C-d>
        endif

    endif
endfunction

" 快捷函数用于制表符和空格之间的切换"
" allow toggling between local and default mode
" https://vim.fandom.com/wiki/Toggle_between_tabs_and_spaces
function! TabToggle()
    if &expandtab
        set noexpandtab
    else
        set expandtab
    endif
endfunction

" *************************************************************************
" basic keymaps
" *************************************************************************
let mapleader = "\<space>"

" easier navigation between split windows
nnoremap <c-j> <c-w>j
nnoremap <c-k> <c-w>k
nnoremap <c-h> <c-w>h
nnoremap <c-l> <c-w>l

" 集成终端中快速退出终端模式
tnoremap <c-q> <c-\><c-n>

" quickly edit this config file, 在新标签页打开vimrc
nnoremap <leader>ve :tabnew $MYVIMRC<CR>
" quickly save and source this config file, 保存并重新加载vimrc
nnoremap <leader>vs :wa<Bar>so $MYVIMRC<CR>

" toggle paste mode, 设置粘贴模式
nnoremap <leader>p :set paste!<CR>

" toggle list char, 打开、关闭可视化符号
nnoremap <leader>l :set list!<CR>

" toggle tab/spaces, 制表符和空格之间的切换
nnoremap <leader>t :call TabToggle()<CR>

" strip trailing whitespaces, 删除全文的行尾空格
" https://vi.stackexchange.com/a/2285
nnoremap <leader>s :let _s=@/<Bar>:%s/\s\+$//e<Bar>:let @/=_s<Bar><CR>

" switch between tabs
nnoremap <leader>] :tabnext<CR>
nnoremap <leader>[ :tabprevious<CR>

" 快速退出、删除当前标签页
nnoremap <leader>q :q<CR>
" 快速保存
nnoremap <leader>w :w<CR>
" 保存全部
nnoremap <leader>e :wa<CR>

" switch between buffers
nnoremap <leader>} :bnext<CR>
nnoremap <leader>{ :bprevious<CR>

" 调整高度
nnoremap <leader>k :resize +1<CR>
nnoremap <leader>j :resize -1<CR>

" 调整宽度
nnoremap <leader>h :vertical resize -1<CR>
nnoremap <leader>l :vertical resize +1<CR>


" *************************************************************************
" plugin manager
" *************************************************************************

" only use basic functions of my-vimrc
if MY_VIMRC_BASIC != 0
    finish
endif

" first we check for git; finish execution if no git is found
if !executable('git')
    call s:ShowDialog('[my-vimrc] The "git" command is missing. '
                \ .'Only basic functions are available.'
                \ ."\nPress ENTER to continue\n")
    finish
endif

let AUTOLOAD_DIR = expand(DATA_DIR.'/autoload')
let PLUGIN_MANAGER_PATH = expand(AUTOLOAD_DIR.'/plug.vim')
let PLUGIN_MANAGER_URL = GITHUB_RAW.'/junegunn/vim-plug/master/plug.vim'
let PLUGIN_MANAGER_PATTERN = ':PlugInstall'

" download the plugin manager if not installed
silent if s:VerifyDownload(PLUGIN_MANAGER_PATH, PLUGIN_MANAGER_PATTERN, 1000) != 0
    " welcome our beloved user
    call s:ShowDialog(MY_VIMRC_WELCOME."\n[my-vimrc] Thank you for using my-vimrc!\n"
                \ ."Press ENTER to download the plugin manager\n")

    " try different ways to download the plugin manager
    if has('win32') && executable('powershell')
        silent execute '!powershell "iwr -useb '.PLUGIN_MANAGER_URL.' |` '
                    \ .'ni '.PLUGIN_MANAGER_PATH.' -Force"'
    elseif has('win32') && executable('certutil')
        silent execute '!(if not exist "'.AUTOLOAD_DIR.'" mkdir "'.AUTOLOAD_DIR.'")'
                    \ .'&& certutil -urlcache -split -f "'.PLUGIN_MANAGER_URL.'"'
                    \ .' "'.PLUGIN_MANAGER_PATH.'"'
    elseif executable('wget')
        silent execute '!mkdir -p '.AUTOLOAD_DIR.' '
                    \ .'&& wget -O '.PLUGIN_MANAGER_PATH.' '.PLUGIN_MANAGER_URL.' '
                    \ .'&& echo "Download successful." || echo "Download failed." '
    elseif executable('curl')
        silent execute '!curl -fLo '.PLUGIN_MANAGER_PATH
                    \ .' --create-dirs '.PLUGIN_MANAGER_URL.' '
                    \ .'&& echo "Download successful." || echo "Download failed." '
    else
        echo '[my-vimrc] No downloader available.'
    endif

    " verify the downloaded file; finish the execution if failed
    if s:VerifyDownload(PLUGIN_MANAGER_PATH, PLUGIN_MANAGER_PATTERN, 1000) != 0
        call s:ShowDialog('[my-vimrc] Unable to download the plugin manager. '
                    \ .'Only basic functions are available. '
                    \ ."\nPlease manually download the plugin manager from "
                    \ .'"https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"'
                    \ .' and save it as "'.PLUGIN_MANAGER_PATH.'"'
                    \ ."\nPress ENTER to continue\n")
        finish
    else
        autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
    endif
endif

call plug#begin()

" --------------------
" color schemes
" --------------------
Plug GITHUB_SITE.'flazz/vim-colorschemes'

" --------------------
" mostly used
" --------------------
Plug GITHUB_SITE.'preservim/nerdtree', { 'on': 'NERDTreeToggle' }
Plug GITHUB_SITE.'Xuyuanp/nerdtree-git-plugin'
Plug GITHUB_SITE.'jistr/vim-nerdtree-tabs'
Plug GITHUB_SITE.'rbong/vim-crystalline', { 'branch': 'vim-7' }
Plug GITHUB_SITE.'mbbill/undotree'
Plug GITHUB_SITE.'preservim/tagbar', { 'on': 'TagbarToggle' }
Plug GITHUB_SITE.'NewComer00/ack.vim', { 'branch': 'patch-1' }
Plug GITHUB_SITE.'vim-scripts/YankRing.vim'
Plug GITHUB_SITE.'ycm-core/YouCompleteMe'

" --------------------
" more convenience
" --------------------
" if has('timers')
"     Plug GITHUB_SITE.'delphinus/vim-auto-cursorline'
" endif
Plug GITHUB_SITE.'luochen1990/rainbow'
Plug GITHUB_SITE.'gosukiwi/vim-smartpairs'
Plug GITHUB_SITE.'airblade/vim-rooter'
Plug GITHUB_SITE.'junegunn/vim-peekaboo'
Plug GITHUB_SITE.'tpope/vim-commentary'
Plug GITHUB_SITE.'farmergreg/vim-lastplace'
" system clipboard
if has('patch-8.2.1337')
    " https://github.com/vim/vim/issues/6591
    Plug GITHUB_SITE.'ojroques/vim-oscyank'
    Plug GITHUB_SITE.'christoomey/vim-system-copy'
else
    Plug GITHUB_SITE.'ojroques/vim-oscyank', { 'commit': '14685fc' }
    Plug GITHUB_SITE.'christoomey/vim-system-copy', { 'commit': '1e5afc4' }
endif
" git related
Plug GITHUB_SITE.'tpope/vim-fugitive'
Plug GITHUB_SITE.'junegunn/gv.vim'
" vim performance
if has('timers') && has('terminal')
    Plug GITHUB_SITE.'dstein64/vim-startuptime'
else
    Plug GITHUB_SITE.'NewComer00/startuptime.vim', { 'branch': 'patch-1' }
endif

call plug#end()


" *************************************************************************
" plugin configs functions
" *************************************************************************
" NERDTree funcions
function! OverrideNERDTreeTabOpen()
  unmap <buffer> t
  nnoremap <buffer> t :call NERDTreeOpenInTabWithSameRoot()<CR>
endfunction

function! NERDTreeOpenInTabWithSameRoot()
  " 获取当前选中的节点
  let node = g:NERDTreeFileNode.GetSelected()
"   if type(node) != type({}) || !node.exists('path')
"     echo "请选择一个文件"
"     return
"   endif

  let filepath = node.path.str()
  if node.path.isDirectory
    echo "不能用 t 打开目录"
    return
  endif

  " 获取当前 NERDTree 的根路径（使用 buffer-local）
  let root_path = b:NERDTree.root.path.str()

  " 使用 nerdtree-tabs 插件打开新标签页（自动加载 NERDTree）
  " execute 'NERDTreeTabsOpen'
  tabnew

  " 切换左侧 NERDTree 窗口，并 cd 到旧目录（以保持根目录一致）
  wincmd h
  execute 'cd' fnameescape(root_path)
  execute 'NERDTreeCWD'

  " 切换到右侧窗口并打开文件
  wincmd l
  execute 'edit' fnameescape(filepath)
endfunction


" *************************************************************************
" plugin configs
" *************************************************************************

" flazz/vim-colorschemes
if exists('plugs') && has_key(plugs, 'vim-colorschemes')
            \ && filereadable(plugs['vim-colorschemes']['dir'].'/colors/molokai.vim')
    colorscheme molokai
    " 设置背景透明度跟随终端
    highlight Normal ctermbg=NONE guibg=NONE
endif

" rbong/vim-crystalline 状态栏设置
function! StatusLine(...)
  return crystalline#mode() . crystalline#right_mode_sep('Line')
        \ . ' %f%h%w%m%r ' . crystalline#right_sep('Line', 'Fill') . '%='
        \ . crystalline#left_sep('Line', 'Fill')
        \ . ' %{&ft} [%{&fenc!=#""?&fenc:&enc}] [%{&ff}] [%{&expandtab?"SPACE":"TAB"}:%{&shiftwidth}] Line:%l/%L Col:%c%V %P '
endfunction
let g:crystalline_statusline_fn = 'StatusLine'
let g:crystalline_theme = 'jellybeans'

" preservim/nerdtree
let NERDTreeWinPos="left"
let NERDTreeShowHidden=1
let NERDTreeMouseMode=2
" disable the original file explorer
let g:loaded_netrw = 1
let g:loaded_netrwPlugin = 1
" lazy load nerdtree when open a directory
" https://github.com/junegunn/vim-plug/issues/424#issuecomment-189343357
augroup nerd_loader
  autocmd!
  autocmd VimEnter * silent! autocmd! FileExplorer
  autocmd BufEnter,BufNew *
        \  if isdirectory(expand('<amatch>'))
        \|   call plug#load('nerdtree')
        \|   execute 'autocmd! nerd_loader'
        \| endif
augroup END
" 推荐开启：切换 tab 时自动重用 NERDTree
let g:nerdtree_tabs_open_on_console_startup = 0
let g:nerdtree_tabs_open_on_new_tab = 1
let g:nerdtree_tabs_smart_startup_focus = 1
let g:nerdtree_tabs_autofind = 1
" 在 NERDTree 中按 t 打开文件到新 tab，保留原目录树结构
autocmd FileType nerdtree call OverrideNERDTreeTabOpen()

" preservim/tagbar
let g:tagbar_position = 'vertical rightbelow'
let g:tagbar_width = max([25, winwidth(0) / 5])

" mileszs/ack.vim
if executable('ag')
    let g:ackprg = 'ag --vimgrep --hidden --ignore .git'
endif

" rainbow/luochen1990, 颜色括号
let g:rainbow_active = 1
let g:rainbow_conf = {
\   'separately': {
\   'nerdtree': 0,
\   }
\}

" vim-scripts/YankRing.vim, 剪切板历史记录
" to avoid <C-p> collision with the ctrlp plugin
let g:yankring_replace_n_pkey = '<m-p>'
let g:yankring_replace_n_nkey = '<m-n>'
" save yankring history in this dir
let s:yankring_dir = expand(DATA_DIR.'/yankring-dir')
if !isdirectory(s:yankring_dir)
    call mkdir(s:yankring_dir, "p", 0700)
endif
let g:yankring_history_dir = s:yankring_dir

" christoomey/vim-system-copy
let g:system_copy_enable_osc52 = 1
if has('win32') && executable('powershell')
    " force cmd.exe to use utf-8 encoding
    " https://stackoverflow.com/questions/57131654/using-utf-8-encoding-chcp-65001-in-command-prompt-windows-powershell-window
    call system('chcp 65001')
    " https://github.com/christoomey/vim-system-copy/pull/35#issue-557371087
    let g:system_copy#paste_command='powershell "Get-Clipboard"'
endif

" *************************************************************************
" extra functions
" *************************************************************************

" test the startup time of Vim
function! TimingVimStartup(sorted)
    let l:cmd = ''
    if has('timers') && has('terminal')
        let l:cmd = 'StartupTime --tries 10'
        if a:sorted == 0
            let l:cmd .= ' --no-sort'
        endif
    else
        let l:cmd = 'StartupTime'
    endif
    execute(l:cmd)
endfunction

" *************************************************************************
" extra keymaps
" *************************************************************************

" functional hotkeys for plugins
nnoremap <silent> <F2> :NERDTreeToggle<CR>
nnoremap <silent> <F3> :call OpenShell()<CR>
nnoremap <silent> <F4> :UndotreeToggle<CR>
nnoremap <silent> <F7> :YRShow<CR>
nnoremap <silent> <F8> :TagbarToggle<CR>
nnoremap <F9> :AckFile!<Space>

inoremap <silent> <F2> <Esc>:NERDTreeToggle<CR>
inoremap <silent> <F3> <Esc>:call OpenShell()<CR>
inoremap <silent> <F4> <Esc>:UndotreeToggle<CR>
inoremap <silent> <F7> <Esc>:YRShow<CR>
inoremap <silent> <F8> <Esc>:TagbarToggle<CR>
inoremap <F9> <Esc>:AckFile!<Space>

cnoremap <silent> <F9> <C-c>

" plugin manager shortcuts
nnoremap <leader>vi :wa<Bar>silent! so $MYVIMRC<CR>:PlugInstall<CR>
nnoremap <leader>vc :wa<Bar>silent! so $MYVIMRC<CR>:PlugClean<CR>
nnoremap <leader>vu :wa<Bar>silent! so $MYVIMRC<CR>:PlugUpdate<CR>
" test vim startup time
nnoremap <leader>vt :call TimingVimStartup(1)<CR>
nnoremap <leader>vT :call TimingVimStartup(0)<CR>

" search the word under the cursor
nnoremap <leader>a :Ack!<CR>
" search the given word
nnoremap <leader>A :Ack!<Space>

" christoomey/vim-system-copy
nmap cy <Plug>SystemCopy
xmap cy <Plug>SystemCopy
nmap cY <Plug>SystemCopyLine
nmap cp <Plug>SystemPaste
xmap cp <Plug>SystemPaste
nmap cP <Plug>SystemPasteLine

