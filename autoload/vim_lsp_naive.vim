function! s:vim_lsp_naive_get_user_vim_dir() abort
  if has('win32') || has('win64')
    return substitute(fnamemodify(expand('~/vimfiles'), ':p'), '[\/]\+$', '', '')
  endif

  return substitute(fnamemodify(expand('~/.vim'), ':p'), '[\/]\+$', '', '')
endfunction

function! s:vim_lsp_naive_get_config_path() abort
  return s:vim_lsp_naive_get_user_vim_dir() . '/vim-lsp.json'
endfunction

let s:lsp_jobs_by_executable = {}

function! s:to_string_or_empty(value) abort
  return type(a:value) == v:t_string ? a:value : string(a:value)
endfunction

function! s:normalize_server_executable(executable) abort
  if type(a:executable) == v:t_string
    let l:value = trim(a:executable)
    return empty(l:value) ? v:null : l:value
  endif

  if type(a:executable) == v:t_list
    let l:command = []
    for l:command_part in a:executable
      let l:part = trim(s:to_string_or_empty(l:command_part))
      if empty(l:part)
        continue
      endif

      call add(l:command, l:part)
    endfor

    return empty(l:command) ? v:null : l:command
  endif

  return v:null
endfunction

function! s:lsp_server_executable_key(executable) abort
  return string(a:executable)
endfunction

function! s:is_job_handle(job) abort
  if type(a:job) == v:t_number
    return a:job > 0
  endif

  return exists('v:t_job') && type(a:job) == v:t_job
endfunction

function! s:is_channel_handle(channel) abort
  if type(a:channel) == v:t_number
    return a:channel > 0
  endif

  return exists('v:t_channel') && type(a:channel) == v:t_channel
endfunction

function! s:is_job_running(job) abort
  if !s:is_job_handle(a:job) || !exists('*job_status')
    return 0
  endif

  return job_status(a:job) ==# 'run'
endfunction

function! s:is_lsp_job_record_running(job_record) abort
  if type(a:job_record) != v:t_dict
    return 0
  endif

  return s:is_job_running(get(a:job_record, 'job', v:null))
endfunction

function! s:running_lsp_job_record_for_executable(executable) abort
  let l:executable_key = s:lsp_server_executable_key(a:executable)
  if !has_key(s:lsp_jobs_by_executable, l:executable_key)
    return v:null
  endif

  let l:job_record = s:lsp_jobs_by_executable[l:executable_key]
  if s:is_lsp_job_record_running(l:job_record)
    return l:job_record
  endif

  call remove(s:lsp_jobs_by_executable, l:executable_key)
  return v:null
endfunction

function! s:append_lsp_job_output(executable_key, stream, payload) abort
  if !has_key(s:lsp_jobs_by_executable, a:executable_key)
    return
  endif

  let l:job_record = s:lsp_jobs_by_executable[a:executable_key]
  if type(l:job_record) != v:t_dict
    return
  endif

  if !has_key(l:job_record, a:stream) || type(l:job_record[a:stream]) != v:t_list
    let l:job_record[a:stream] = []
  endif

  if type(a:payload) == v:t_list
    call extend(l:job_record[a:stream], a:payload)
  else
    call add(l:job_record[a:stream], s:to_string_or_empty(a:payload))
  endif

  let s:lsp_jobs_by_executable[a:executable_key] = l:job_record
endfunction

function! s:on_lsp_server_stdout(executable_key, channel, payload) abort
  call s:append_lsp_job_output(a:executable_key, 'stdout', a:payload)
endfunction

function! s:on_lsp_server_stderr(executable_key, channel, payload) abort
  call s:append_lsp_job_output(a:executable_key, 'stderr', a:payload)
endfunction

function! s:on_lsp_server_exit(executable_key, job, status) abort
  if !has_key(s:lsp_jobs_by_executable, a:executable_key)
    return
  endif

  let l:job_record = s:lsp_jobs_by_executable[a:executable_key]
  if type(l:job_record) != v:t_dict
    call remove(s:lsp_jobs_by_executable, a:executable_key)
    return
  endif

  if string(get(l:job_record, 'job', v:null)) !=# string(a:job)
    return
  endif

  call remove(s:lsp_jobs_by_executable, a:executable_key)
endfunction

function! s:start_lsp_server_job(executable) abort
  if !exists('*job_start') || !exists('*job_getchannel')
    return 0
  endif

  let l:executable_key = s:lsp_server_executable_key(a:executable)
  let l:job = job_start(a:executable, {
        \ 'in_io': 'pipe',
        \ 'out_io': 'pipe',
        \ 'err_io': 'pipe',
        \ 'out_mode': 'raw',
        \ 'err_mode': 'raw',
        \ 'out_cb': function('s:on_lsp_server_stdout', [l:executable_key]),
        \ 'err_cb': function('s:on_lsp_server_stderr', [l:executable_key]),
        \ 'exit_cb': function('s:on_lsp_server_exit', [l:executable_key]),
        \ })
  if !s:is_job_handle(l:job)
    return 0
  endif

  let l:channel = job_getchannel(l:job)
  if !s:is_channel_handle(l:channel)
    if exists('*job_stop')
      call job_stop(l:job)
    endif
    return 0
  endif

  if exists('*ch_status') && ch_status(l:channel) ==# 'closed'
    if exists('*job_stop')
      call job_stop(l:job)
    endif
    return 0
  endif

  let s:lsp_jobs_by_executable[l:executable_key] = {
        \ 'job': l:job,
        \ 'channel': l:channel,
        \ 'stdout': [],
        \ 'stderr': []
        \ }
  return 1
endfunction

function! s:stop_lsp_job_record(job_record) abort
  if type(a:job_record) != v:t_dict
    return
  endif

  let l:job = get(a:job_record, 'job', v:null)
  if !s:is_job_handle(l:job) || !exists('*job_stop')
    return
  endif

  if exists('*job_status') && job_status(l:job) !=# 'run'
    return
  endif

  call job_stop(l:job, 'kill')
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

function! vim_lsp_naive#on_vim_leave() abort
  let l:jobs_by_executable = copy(s:lsp_jobs_by_executable)
  let s:lsp_jobs_by_executable = {}
  for l:executable_key in keys(l:jobs_by_executable)
    call s:stop_lsp_job_record(get(l:jobs_by_executable, l:executable_key, v:null))
  endfor
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
      let l:executable = s:normalize_server_executable(get(l:server, 'executable', v:null))
      if l:executable is v:null
        return
      endif

      if s:running_lsp_job_record_for_executable(l:executable) isnot v:null
        return
      endif

      call s:start_lsp_server_job(l:executable)
      return
    endif
  endfor
endfunction
