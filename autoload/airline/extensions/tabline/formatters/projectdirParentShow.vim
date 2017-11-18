augroup UMisc_FilePath_Capture
  autocmd!
  autocmd BufReadPre * let b:umisc_file_abs_path = expand('%:p')
augroup END

function! s:buildTabNameFromRule(fpath, pat, ruledict) abort
  if a:fpath !~# a:pat
    return ''
  endif
  let newpath = substitute(a:fpath, a:pat, a:ruledict['replace'], '')
  if newpath =~# a:ruledict['result'][0]
    return substitute(newpath, a:ruledict['result'][0], a:ruledict['result'][1], '')
  else
    return a:ruledict['default']
  endif
endfunction

function! s:getTabNameByRule(fpath) abort
  if !exists('g:umisc_tab_naming_patterns')
    return ''
  endif
  for dic in g:umisc_tab_naming_patterns
    for [pat, ddic] in items(dic)
      let ret = s:buildTabNameFromRule(a:fpath, pat, ddic)
      if len(ret)
	return ret
      endif
    endfor
  endfor
  return ''
endfunction

function! airline#extensions#tabline#formatters#projectdirParentShow#format(bufnr, buffers) abort
  let fpath = getbufvar(a:bufnr, 'umisc_file_abs_path', '')
  if len(fpath)
    let ret = s:getTabNameByRule(fpath)
    if len(ret)
      return ret
    endif
  endif
  let _ = getbufvar(a:bufnr, 'local_vimrc_path')
  if _ !=# ''
    return fnamemodify(_, ':t')
  endif
  return airline#extensions#tabline#formatters#default#format(a:bufnr, a:buffers)
endfunction

