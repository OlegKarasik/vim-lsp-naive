function! s:vim_lsp_naive_get_user_vim_dir() abort
  if has('win32') || has('win64')
    return substitute(fnamemodify(expand('~/vimfiles'), ':p'), '[\/]\+$', '', '')
  endif

  return substitute(fnamemodify(expand('~/.vim'), ':p'), '[\/]\+$', '', '')
endfunction

function! s:vim_lsp_naive_get_config_path() abort
  return s:vim_lsp_naive_get_user_vim_dir() . '/vim-lsp.json'
endfunction

function! vim_lsp_naive#config() abort
  let l:user_vim_dir = s:vim_lsp_naive_get_user_vim_dir()
  let l:config_path = s:vim_lsp_naive_get_config_path()

  if getftype(l:user_vim_dir) !=# 'dir'
    call mkdir(l:user_vim_dir, 'p')
  endif

  if !filereadable(l:config_path)
    call writefile(['{}'], l:config_path)
  endif

  execute 'edit ' . fnameescape(l:config_path)
endfunction

function! vim_lsp_naive#register_plug_mappings() abort
  call s:register_plug_mapping('<Plug>(LspConfig)', '<Cmd>call vim_lsp_naive#config()<CR>')
endfunction

function! s:register_plug_mapping(lhs, rhs) abort
  if empty(maparg(a:lhs, 'n'))
    execute 'nnoremap <silent> ' . a:lhs . ' ' . a:rhs
  endif
endfunction

function! vim_lsp_naive#on_buf_enter(bufnr) abort
  let l:bufnr = str2nr(a:bufnr)
  if l:bufnr <= 0
    return
  endif

  if getbufvar(l:bufnr, '&buftype') !=# ''
    return
  endif

  let l:filetype = getbufvar(l:bufnr, '&filetype')
  if empty(l:filetype)
    return
  endif

  let l:config_path = s:vim_lsp_naive_get_config_path()
  if !filereadable(l:config_path)
    return
  endif

  let l:raw_lines = readfile(l:config_path)
  if empty(l:raw_lines)
    return
  endif

  let l:raw_content = trim(join(l:raw_lines, "\n"))
  if empty(l:raw_content)
    return
  endif

  let l:config = json_decode(l:raw_content)
  if type(l:config) != v:t_dict
    return
  endif

  if !has_key(l:config, 'servers')
        \ || type(l:config.servers) != v:t_list
        \ || empty(l:config.servers)
    return
  endif

  for l:server in l:config.servers
    if type(l:server) != v:t_dict
      continue
    endif

    if get(l:server, 'filetype', '') ==# l:filetype
      echomsg 'found ' . string(l:server)
      return
    endif
  endfor
endfunction
