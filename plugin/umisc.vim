
augroup QFixToggle
  autocmd!
  autocmd BufWinEnter quickfix let g:qfix_win = bufnr("$")
  autocmd BufWinLeave * if exists("g:qfix_win") && expand("<abuf>") == g:qfix_win | unlet! g:qfix_win | endif
augroup END

command! -nargs=0 RandomLine      call umisc#GoToRandomLine()
command! -nargs=0 RebuildAllCTags call umisc#RebuildAllDependentCTags()
command! -nargs=0 MakeTmuxBuild   call umisc#Make_Tmux_Build(g:tmuxmake_targets)
command! -nargs=? Underline       call umisc#Underline(<q-args>)
command! -nargs=? Scriptnames     call umisc#Filter_Lines('scriptnames', <q-args>)
command! -range=% Source          call umisc#SourceRange(<line1>,<line2>)
command! -range=% ClearAnsi       call umisc#ClearAnsiSequences(<line1>, <line2>)
command! -nargs=0 -bar        Hexmode   call umisc#ToggleHex()
command! -nargs=? -range -bar PP        call umisc#PrintWithSearchHighlighted(<line1>,<line2>,<q-args>)
command! -nargs=0 -range=%    Tab2Space call umisc#Tab2Space(<line1>,<line2>)
command! -nargs=0 -range=%    Space2Tab call umisc#Space2Tab(<line1>,<line2>)
command! -nargs=? -bang       QFix      call umisc#QFixToggle(<bang>0)

