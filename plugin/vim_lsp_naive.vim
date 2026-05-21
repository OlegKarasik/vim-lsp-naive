if exists('g:loaded_vim_lsp_naive')
  finish
endif
let g:loaded_vim_lsp_naive = 1

nnoremap <silent> <Plug>(LspConfig) <Cmd>call vim_lsp_naive#config()<CR>

command! -bar -nargs=0 LspConfig call vim_lsp_naive#config()

augroup vim_lsp_naive
  autocmd!
  autocmd BufReadPost * call vim_lsp_naive#on_buf_read_post(expand('<abuf>'))
augroup END
