" 开启语法高亮功能
syntax enable

set background=dark

colorscheme solarized

hi Normal ctermbg=NONE


" 设置 Vim 标签的标题为“上一级目录/文件名”
set t_ts=k
set t_fs=\

set title titlestring=[%{split(getcwd(),'\/')[-1]}/%t]
"%{split(getcwd(),'\/')[0]}
"%{split(%f,'\/')[-1]}
"%{getcwd()}
"%{hostname()}

" 开启行号显示
set number

" 高亮显示搜索结果
set hlsearch

" 自适应不同语言的智能缩进
filetype indent on

" 搜索未输入完成即开始匹配显示
set is
