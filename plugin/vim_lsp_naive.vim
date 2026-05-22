if exists('g:loaded_vim_lsp_naive')
  finish
endif
let g:loaded_vim_lsp_naive = 1

nnoremap <silent> <Plug>(LspConfig) <Cmd>call vim_lsp_naive#config()<CR>

command! -bar -nargs=0 LspConfig call vim_lsp_naive#config()

augroup vim_lsp_naive
  autocmd!
  autocmd BufEnter * call vim_lsp_naive#on_buf_enter(expand('<abuf>'))
augroup END
