scriptencoding utf-8

if exists('g:loaded_umisc_autoload') || !exists('g:loaded_umisc_plugin')
  finish
endif
let g:loaded_umisc_autoload = 1


function! umisc#FpathFilterRelStrs(fpath) abort
  let ret = a:fpath
  let updir_i = strridx(ret, '../')
  if updir_i != -1
    let ret = ret[updir_i+3:]
  endif
  let curdir_i = strridx(ret, './')
  if curdir_i != -1
    let ret = ret[curdir_i+2:]
  endif
  let curly_close = strridx(ret, '}/')
  if curly_close != -1
    let curly_open = strridx(ret, '${', curly_close)
    if curly_open != -1
      let ret = (curly_open > 0 ? ret[0:curly_open-1] : '') . ret[curly_close+2:]
    endif
  endif
  return ret
endfunction

function! umisc#DirectorySettled(curPath) abort
    let b:local_vimrc_path = a:curPath
    let l:lvimrc = a:curPath . '/.lvimrc'
    if filereadable(l:lvimrc)
      exe 'source ' . escape(l:lvimrc, ' \$,')
    else
      let l:vcs_dir = umisc#GetDirectoryVCSDotDir(a:curPath, 1)
      if l:vcs_dir !=# '' && isdirectory(l:vcs_dir)
        call umisc#AppendPathsRelativeToLocalVimRc('.')
        if !filereadable(l:vcs_dir . '/tags')
          call umisc#RebuildAllDependentCTags()
          let l:tgs = &tags
          let &tags = ''
          let &tags = l:tgs
        endif
      endif
    endif
endfunction

function! umisc#AppendPathsRelativeToLocalVimRc(dir) abort
  let l:path = b:local_vimrc_path.'/'.a:dir
  let l:vcs_dir = umisc#GetDirectoryVCSDotDir(l:path, 1)
  if a:dir ==# '.'
    let g:autotagTagsDir = umisc#GetDirectoryVCSDotDir(l:path, 0)
    let &tags = (l:vcs_dir!=#'' ? l:vcs_dir.'/tags' : l:path.'/tags')
    let &path = l:path
  else
    let &tags = &tags . ',' . (l:vcs_dir!=#'' ? l:vcs_dir.'/tags' : l:path.'/tags')
    let &path = &path . ',' . l:path
  endif
endfunction

function! umisc#GetDirectoryVCSDotDir(dir, isfulldir) abort
  if isdirectory(fnamemodify(a:dir.'/.svn', ':p'))
    return a:isfulldir ? a:dir.'/.svn' : '.svn'
  endif
  if isdirectory(fnamemodify(a:dir.'/.git', ':p'))
    return a:isfulldir ? a:dir.'/.git' : '.git'
  endif
  return ''
endfunction

function! s:GetParentOfAndVCSDotDirTagsFile(tagspath) abort
  let l:tagsdir = fnamemodify(a:tagspath, ':p:h')
  let l:dirparent = fnamemodify(a:tagspath, ':p:h:h')
  let l:p = l:tagsdir[strlen(l:dirparent)+1:]
  if l:p ==# '.svn'
    return [l:dirparent, l:p]
  elseif l:p ==# '.git'
    return [l:dirparent, l:p]
  else
    return [l:tagsdir, '']
  endif
endfunction

function! umisc#RebuildAllDependentCTags() abort
  let l:tags = &tags
  let l:cwd = getcwd()
  for t in split(l:tags, ',')
    if t ==# ''
      continue
    endif
    " let l:tparent=''
    " let l:vcs_dir=''
    let [l:tparent, l:vcs_dotdir] = s:GetParentOfAndVCSDotDirTagsFile(fnamemodify(t, ':p'))
    " Do not rebuild existing tags if directory is external (dependant) ...
    if l:tparent != l:cwd
      " ... If directory is at external location then it needn't be done here.
      if filereadable(l:tparent.'/'.l:vcs_dotdir.'/tags')
        echom 'Skipping: ' . l:tparent . ' (tags already existing)'
        continue
      endif
    endif
    if isdirectory(l:tparent) != 0
      echom l:tparent.' : '.l:vcs_dotdir
      if l:vcs_dotdir !=# ''
        call system('cd '.shellescape(l:tparent.'/'.l:vcs_dotdir).'; rm -f tags; ctags -f tags -R ..')
      else
        call system('cd '.shellescape(l:tparent).'; rm -f tags; ctags -f tags -R .')
      endif
    else
      echohl ErrorMsg
      echom 'Directory ' . l:tparent . ' is non existent!'
      echohl None
    endif
  endfor
  echom 'DONE'
endfunction

function! umisc#GoToRandomLine() abort
  ruby Vim.command 'normal! ' + (VIM::Buffer.current.length * rand).ceil.to_s + 'gg'
  " execute 'normal! '.(system('sh -c 'echo -n $RANDOM'') % line('$')).'G'
  " execute 'normal! '.(matchstr(system('od -vAn -N3 -tu4 /dev/urandom'), '^\_s*\zs.\{-}\ze\_s*$') % line('$')).'G'
endfunction

" jump to nearest line ending with v:count
" thus if you are on line 20234500 and you type 80 you'll jump to 20234480
" credits to ujihisa who had this idea
" problem: you cannot jump to 05, becaues 5 will be passed via v:count
"
" https://github.com/MarcWeber/vim-addon-other/blob/master/autoload/vim_addon_other.vim
function! umisc#GotoLine_WithoutInitials(visual_select) abort
    let c = v:count
    let half = ('1'.repeat('0',len(c))) / 2
    let lnum = line('.')[:-len(c)-1].c
    if lnum > half + line('.')
      let lnum -= 2* half
    endif
    if a:visual_select
      exec 'normal! V'.lnum.'G'
    else
      exec 'normal '.lnum.'G'
    endif
endfunction

function! umisc#SearchForwLastSearch() abort
  if @/ ==# ''
    return '/\<Up>\<CR>'
  else
    return '/\<CR>'
  endif
endfunction

function! s:SetSearch(sstr) abort
  let @/=@/
  return a:sstr
endfunction

function! umisc#FlashLocn() abort
  hi CursorColumn guibg=yellow
  hi CursorLine guibg=yellow
  set cul cuc
  redraw!
  "sleep 1m
  set nocul nocuc
endfunction

function! umisc#ApplyPatch() abort
  let l:tmpfilename = tempname() . '.patch'
  let l:s = @"
  call writefile(split(l:s, '\n'), l:tmpfilename, 'b')
  " using system() does not rewash the screen
  let l:res = system('patch -p1 < ' .  shellescape(l:tmpfilename))
  echomsg 'Shell result ->'
  echomsg v:shell_error
  call delete(l:tmpfilename)
  echomsg l:res
endfunction

function! umisc#Make_Tmux_Build(targets) abort
  update
  if a:targets ==# ''
    make
  elseif a:targets ==# '__'
    make %
  else
    exec 'SlimuxShellRun make ' . a:targets
  endif
endfunction

function! s:MapPumInsert(key, insertSpaceAfter) abort
  if !a:insertSpaceAfter
    exec 'imap <expr> ' . a:key . ' pumvisible() ? \"\<C-y>'.a:key.'" : "'.a:key.'"'
  else
    exec 'imap <expr> ' . a:key . ' pumvisible() ? neocomplete#close_popup()'.a:key.'\<Space>\" : \"'.a:key.'"'
  endif
endfunction

function! s:IsHereAComment() abort
  let syn = synIDtrans(synID(line('.'), col('.')-1, 1))
  return syn == hlID('Comment')
endfunction

function! umisc#IsSemicolonAppropriateHere() abort
  " TODO:
  " Write a regex which will execute faster
  " Think about plugin extraction of the idea
  let cline = getline('.')
  let lastchar  = cline[col('$')-2]
  let firstchar = cline[0]
  if col('$') == col('.') && lastchar !=# ';' && lastchar !=# '{' && lastchar !=# '}' && lastchar !=# ',' &&
        \ lastchar !=# ':' && firstchar !=# '#' && cline !~# '^\s*$' && lastchar !=# '\\' && !s:IsHereAComment()
    return 1
  endif
  return 0
endfunction

function! umisc#YieldSemicolonIfAppropriate() abort
  let l:ret = ''
  if pumvisible()
    let l:ret = "\<C-y>".neocomplete#smart_close_popup()
  endif
  if umisc#IsSemicolonAppropriateHere()
    let l:ret .= ';'
  endif
  return l:ret
endfunction

function! s:IsTagsActiveFileType(ft) abort
  if a:ft ==# ''
    return 0
  endif
  return stridx('c,cpp,java,javascript,python,actionscript,sh,go', a:ft) >= 0
endfunction

"wrapper on signs' update: wraps quickfixsigns and DynamicSigns
function! UpdateSigns_() abort
  if exists('g:loaded_quickfixsigns') && g:loaded_quickfixsigns == 0
    call QuickfixsignsUpdate()
  endif
  if exists('g:loaded_Signs') && g:loaded_Signs == 0
    UpdateSigns
  endif
endfunction

" save/load quickfix list {{{
function! umisc#SaveQuickFixList(fname) abort
  let list = getqflist()
  for i in range(len(list))
    if has_key(list[i], 'bufnr')
      let list[i].filename = fnamemodify(bufname(list[i].bufnr), ':p')
      unlet list[i].bufnr
    endif
  endfor
  let string = string(list)
  let lines = split(string, "\n")
  call writefile(lines, a:fname)
endfunction

function! umisc#LoadQuickFixList(fname) abort
  let lines = readfile(a:fname)
  let string = join(lines, "\n")
  call setqflist(eval(string))
endfunction
" }}}

function! umisc#QFixCloseAndCheck() abort
  if exists('g:qfix_win')
    cclose
    unlet! g:qfix_win
    return 1
  elseif &swapfile == 0 && &buftype ==# 'nofile' && &buflisted == 0
    exec 'quit'
    return 2
  endif
  return 0
endfunction

function! umisc#QFixToggle(forced) abort
  if exists('g:qfix_win') && a:forced == 0
    cclose
    unlet! g:qfix_win
  else
    copen 15
    let g:qfix_win = bufnr('$')
  endif
endfunction

function! umisc#GuiTabLabel() abort
  let label = ''
  let bufnrlist = tabpagebuflist(v:lnum)
  " Add '+' if one of the buffers in the tab page is modified
  for bufnr in bufnrlist
    if getbufvar(bufnr, '&modified')
      let label = '+'
      break
    endif
  endfor
  " Append the tab number
  let label .= v:lnum.': '
  " Append the buffer name
  let name = bufname(bufnrlist[tabpagewinnr(v:lnum) - 1])
  if name ==# ''
    " give a name to no-name documents
    if &buftype ==# 'quickfix'
      let name = '[Quickfix List]'
    else
      let name = '[No Name]'
    endif
  else
    " get only the file name
    let name = fnamemodify(name,':t')
  endif
  let label .= name
  " Append the number of windows in the tab page
  let wincount = tabpagewinnr(v:lnum, '$')
  return label . '  [' . wincount . ']'
endfunction

function! umisc#OpenExplore(...) abort
  if bufname(bufnr('%')) ==? ''
    silent! Explore
  else
    if a:0 > 0 && a:1 ==# 'vertical'
      Vexplore
    else
      silent! Sexplore
    endif
  endif
endfunction

" with ctags you can search for tags.DB upward hieararchy via :set tags=tags;/
" but cscope cannot do that withuot helper like this one
function! umisc#LoadCscope() abort
  let db = findfile('cscope.out', '.;')
  if (!empty(db))
    let path = strpart(db, 0, match(db, '/cscope.out$'))
    set nocscopeverbose " suppress 'duplicate connection' error
    exe 'cs add ' . db . ' ' . path
    set cscopeverbose
  endif
endfunction

function! umisc#DecAndHex(number) abort
  let ns = '[.,;:''"<>()^_lL"]'      " number separators
  if a:number =~? '^' . ns. '*[-+]\?\d\+' . ns . '*$'
    let dec = substitute(a:number, '[^0-9+-]*\([+-]\?\d\+\).*','\1','')
    echo dec . printf('  ->  0x%X, -(0x%X)', dec, -dec)
  elseif a:number =~? '^' . ns. '*\%\(h''\|0x\|#\)\?\(\x\+\)' . ns . '*$'
    let hex = substitute(a:number, '.\{-}\%\(h''\|0x\|#\)\?\(\x\+\).*','\1','')
    echon '0x' . hex . printf('  ->  %d', eval('0x'.hex))
    if strpart(hex, 0,1) =~? '[89a-f]' && strlen(hex) =~? '2\|4\|6'
      " for 8/16/24 bits numbers print the equivalent negative number
      echon ' ('. float2nr(eval('0x'. hex) - pow(2,4*strlen(hex))) . ')'
    endif
    echo
  else
    echo 'NaN'
  endif
endfunction

function! umisc#VimProcMake() abort
  let sub = vimproc#popen2(':make')
  let res = ''
  while !sub.stdout.eof
    let res .= sub.stdout.read()
  endwhile
  let [cond, status] = sub.waitpid()
  unlet! cond
  call setqflist([])
  call vimproc#write('/dev/quickfix', res)
  if status == 0
    cclose
  else
    copen
  endif
endfunction

function! umisc#TDD_Mode() abort
  SyntasticToggleMode
  " au BufWritePost * :call QuickfixsignsClear('qfl')|call umisc#VimProcMake()
  au BufWritePost * call umisc#VimProcMake()
endfunction

function! umisc#Underline(chars) abort
  let chars = empty(a:chars) ? '-' : a:chars
  let nr_columns = virtcol('$') - 1
  let uline = repeat(chars, (nr_columns / len(chars)) + 1)
  put =strpart(uline, 0, nr_columns)
endfunction

function! s:SwapKeys(a, b) abort
  normal! 'exec noremap  ' . a:a . ' ' . a:b
  normal! 'exec noremap  ' . a:b . ' ' . a:a
  normal! 'exec onoremap ' . a:a . ' ' . a:b
  normal! 'exec onoremap ' . a:b . ' ' . a:a
  normal! 'exec xnoremap ' . a:a . ' ' . a:b
  normal! 'exec xnoremap ' . a:b . ' ' . a:a
endfunction

" Execute 'cmd' while redirecting output.
" Delete all lines that do not match regex 'filter' (if not empty).
" Delete any blank lines.
" Delete '<whitespace><number>:<whitespace>' from start of each line.
" Display result in a scratch buffer.
function! umisc#Filter_Lines(cmd, filter) abort
  let save_more = &more
  set nomore
  redir => lines
  silent execute a:cmd
  redir END
  let &more = save_more
  new
  setlocal buftype=nofile bufhidden=hide noswapfile nospell
  put =lines
  g/^\s*$/d
  %s/^\s*\d\+:\s*//e
  if !empty(a:filter)
    execute 'v/' . a:filter . '/d'
  endif
  0
endfunction

" command PP: print lines like :p or :# but with with current search pattern highlighted
function! umisc#PrintWithSearchHighlighted(line1, line2, arg) abort
  let line=a:line1
  while line <= a:line2
    echo ''
    if a:arg =~# '#'
      echohl LineNr
      echo strpart(' ',0,7-strlen(line)).line.'\t'
      echohl None
    endif
    let l=getline(line)
    let index=0
    while 1
      let b=match(l,@/,index)
      if b==-1 |
        echon strpart(l,index)
        break
      endif
      let e=matchend(l,@/,index) |
      echon strpart(l,index,b-index)
      echohl Search
      echon strpart(l,b,e-b)
      echohl None
      let index = e
    endw
    let line=line+1
  endw
endfunction

function! umisc#VimLock(enable) abort
  if a:enable
    inoremap a 1
    inoremap s 2
    inoremap d 3
    inoremap f 4
    inoremap g 5
    inoremap h 6
    inoremap j 7
    inoremap k 8
    inoremap l 9
    inoremap ; 0
    inoremap <Esc> <Esc>:call umisc#VimLock(0)<CR>
  else
    iunmap a
    iunmap s
    iunmap d
    iunmap f
    iunmap g
    iunmap h
    iunmap j
    iunmap k
    iunmap l
    iunmap ;
    iunmap <Esc>
  endif
endfunction

function! umisc#TwiddleCase(str) abort
  if a:str ==# toupper(a:str)
    let result = tolower(a:str)
  elseif a:str ==# tolower(a:str)
    let result = substitute(a:str,'\(\<\w\+\>\)', '\u\1', 'g')
  else
    let result = toupper(a:str)
  endif
  return result
endfunction

let s:indentation_guides_enabled = 0
function! umisc#ToggleIndGuides_RC() abort
  if s:indentation_guides_enabled == 1
    " IndGuide!
    IndentGuidesDisable
    let s:indentation_guides_enabled = 0
  else
    " IndGuide
    IndentGuidesEnable
    let s:indentation_guides_enabled = 1
  endif
endfunction

" Trans to/from Turkish dotted char form {{{
let g:letters_map_en_tr_forward = {
      \ 'o':'ö', 'c':'ç', 'g':'ğ', 's':'ş', 'i':'ı', 'u':'ü',
      \  'O':'Ö', 'C':'Ç', 'G':'Ğ', 'S':'Ş', 'I':'İ', 'U':'Ü'
      \ }
let g:letters_map_en_tr_reverse = {
      \ 'ö':'o', 'ç':'c', 'ğ':'g', 'ş':'s', 'ı':'i', 'ü':'u',
      \  'Ö':'O', 'Ç':'C', 'Ğ':'G', 'Ş':'S', 'İ':'I', 'Ü':'U'
      \ }
function! umisc#SwapTrCharsToFromEn() abort
  let l:saved_reg = @k
  norm "kyl
  let l:curletter = @k
  let @k = l:saved_reg
  if has_key(g:letters_map_en_tr_forward, l:curletter)
    exec "norm \"_xi" . g:letters_map_en_tr_forward[l:curletter]
  elseif has_key(g:letters_map_en_tr_reverse, l:curletter)
    exec "norm \"_xi" . g:letters_map_en_tr_reverse[l:curletter]
  endif
  norm l
endfunction
" }}}

let g:rainbowparantheses_enabled_RC=0
function! umisc#RainbowParanthesisEnableAll_RC() abort
  if g:rainbowparantheses_enabled_RC == 0
    RainbowParenthesesToggle
    " ToggleRaibowParenthesis
    " RainbowParenthesesLoadRound
    " call rainbow_parenthsis#LoadRound ()
    RainbowParenthesesLoadSquare
    " call rainbow_parenthsis#LoadSquare ()
    RainbowParenthesesLoadBraces
    " call rainbow_parenthsis#LoadBraces ()
    RainbowParenthesesLoadChevrons
    " call rainbow_parenthsis#LoadChevrons ()
    let g:rainbowparantheses_enabled_RC=1
  endif
endfunction

" Next and Last {{{
" Motion for "next/last object". For example, "din(" would go to the next "()" pair
" and delete its contents.
function! umisc#NextTextObject(motion, dir) abort
  let c = nr2char(getchar())
  if c ==# 'b'
      let c = '('
  elseif c ==# 'B'
      let c = '{'
  elseif c ==# 'd'
      let c = '['
  elseif c ==# 'q'
      let c = '"'
  endif
  exe 'normal! ' . a:dir . c . 'v' . a:motion . c
endfunction
" }}}

" Source a range of visually selected vimscript
function! umisc#SourceRange(startline, endline) abort
  let l:tmp = tempname()
  call writefile(getline(a:startline, a:endline), l:tmp)
  execute 'source ' . l:tmp
  call delete(l:tmp)
endfunction

" there is also a program named 'ansifilter' which filters out ansi escapes
" unsuccessfully.
function! umisc#ClearAnsiSequences(line0, line1) abort
  exec a:line0 . ',' . a:line1 . 's/\e\[[[:digit:];]*m//ge'
  exec a:line0 . ',' . a:line1 . 's/\e(B//ge'
  " TODO: This substitution sometimes remains comma behind because of the
  " pattern '[36;1H,'. The situation should be fixed after deeper
  " understanding of the issue.
  exec a:line0 . ',' . a:line1 . 's/\e\[\d\+;\d\+\w//ge'
endfunction

function! umisc#Space2Tab(line0, line1) abort
  exe ''.a:line0.','.a:line1."s/^\\(\\ \\{".&ts."\\}\\)\\+/\\=substitute(submatch(0), ' \\{".&ts."\\}', '\\t', 'g')"
endfunction

function! umisc#Tab2Space(line0, line1) abort
  exe ''.a:line0.','.a:line1."s/^\\t\\+/\\=substitute(submatch(0), '\\t', repeat(' ', ".&ts."), 'g')"
endfunction

" fixing arrow keys on terminal Vim
" Two ideas are..
" 1) set <Left>=[1;3D
" 2) (i)(nore)map <Esc>OC <Right>
" using the first idea is logical for portability reasons.
function! s:Allmap(mapping) abort
  execute 'map'  . a:mapping
  execute 'map!' . a:mapping
endfunction

function! umisc#FixTerminalKeys() abort
  if !has('gui_running')
    call s:Allmap(' <Esc>[1;3D <Left>')
    call s:Allmap(' <Esc>[1;3A <Up>')
    call s:Allmap(' <Esc>[1;3B <Down>')
    call s:Allmap(' <Esc>[1;3C <Right>')
    call s:Allmap(' <Esc>OD    <Left>')
    call s:Allmap(' <Esc>OA    <Up>')
    call s:Allmap(' <Esc>OB    <Down>')
    call s:Allmap(' <Esc>OC    <Right>')
    call s:Allmap(' <Esc>}     }')
    call s:Allmap(' <Esc>{     {')
    call s:Allmap(' <Esc>[     [')
    call s:Allmap(' <Esc>]     ]')
    call s:Allmap(' <Esc>~     ~')
    call s:Allmap(' <Esc>@     @')
    call s:Allmap(' <Esc>#     #')
    call s:Allmap(' <Esc>$     $')
    call s:Allmap(' <Esc>\     \')
    call s:Allmap(' <Esc>\|    \|')
  else
    call s:Allmap(' <M-Left>  <Left>')
    call s:Allmap(' <M-Right> <Right>')
    call s:Allmap(' <M-Up>    <Up>')
    call s:Allmap(' <M-Down>  <Down>')
    call s:Allmap(' þ         ~')
    call s:Allmap(' À         @')
    call s:Allmap(' £         #')
  endif
endfunction

function! umisc#ToggleHex() abort
  " hex mode should be considered a read-only operation
  " save values for modified and read-only for restoration later,
  " and clear the read-only flag for now
  let l:modified=&mod
  let l:oldreadonly=&readonly
  let &readonly=0
  let l:oldmodifiable=&modifiable
  let &modifiable=1
  if !exists('b:editHex') || !b:editHex
    " save old options
    let b:oldft=&ft
    let b:oldbin=&bin
    " set new options
    setlocal binary " make sure it overrides any textwidth, etc.
    let &ft='xxd'
    " set status
    let b:editHex=1
    " switch to hex editor
    %!xxd
  else
    " restore old options
    let &ft=b:oldft
    if !b:oldbin
      setlocal nobinary
    endif
    " set status
    let b:editHex=0
    " return to normal editing
    %!xxd -r
  endif
  " restore values for modified and read only state
  let &mod=l:modified
  let &readonly=l:oldreadonly
  let &modifiable=l:oldmodifiable
endfunction

function umisc#TabNextRelatively(n) abort
  let l:jmp = (tabpagenr() + a:n) % tabpagenr('$')
  if l:jmp > 0
    exec 'tabnext ' . l:jmp
  else
    tablast
  endif
endfunction

function umisc#TabPrevRelatively(n) abort
  exec 'tabprev ' . a:n
endfunction

" vim:fdm=marker
