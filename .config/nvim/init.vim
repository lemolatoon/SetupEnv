source ~/.vimrc

" launch terminal instead of launching new tab
nnoremap <silent> @t :tabe<CR>:terminal<CR>
" exchenge mode from terminal to normal by jj 
tnoremap <silent> jj <C-\><C-n>

set shiftwidth=2
set tabstop=2
set expandtab

autocmd TermOpen * startinsert

