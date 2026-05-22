if exists('g:loaded_vim_lsp_naive')
  finish
endif
let g:loaded_vim_lsp_naive = 1

command! -bar -nargs=0 LspConfig call vim_lsp_naive#config()
call vim_lsp_naive#register_plug_mappings()

augroup vim_lsp_naive
  autocmd!
  autocmd BufEnter * call vim_lsp_naive#on_buf_enter(expand('<abuf>'))
augroup END
