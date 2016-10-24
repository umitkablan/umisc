
function! airline#extensions#tabline#formatters#projectdirParentShow#format(bufnr, buffers)
  let _ = getbufvar(a:bufnr, 'local_vimrc_path')
  if _ != ""
    return fnamemodify(_, ':t')
  endif
  return airline#extensions#tabline#formatters#default#format(a:bufnr, a:buffers)
endfunction

