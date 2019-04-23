if exists("g:loaded_sbsh") || !has("terminal") || &cp || v:version < 800
  finish
endif

let g:loaded_sbsh = 1

" au BufRead,BufNewFile *.sbsh set syntax=haskell

if !exists("g:sbsh_flash_duration")
  let g:sbsh_flash_duration = 150
end

if !exists("g:sbsh_preserve_curpos")
  let g:sbsh_preserve_curpos = 1
end

if !exists("g:sbsh_exe")
  let g:sbsh_exe = "/Users/sideboard/NewCodez/SBShell/sbsh"
end

let s:parent_path = fnamemodify(expand("<sfile>"), ":p:h:s?/plugin??")


function! s:SbshStart()
  execute ("below terminal ++rows=10 " . g:sbsh_exe)
  execute ("file sbsh")
  wincmd p
endfunction


function! s:SbshSend(text)
  let pieces = s:_EscapeText(a:text)
  for piece in pieces
    call term_sendkeys("sbsh", piece . "\<CR>")
  endfor
endfunction

""""""""""
" Helpers
""""""""""

function! s:_EscapeText(text)
  if exists("&filetype")
    let custom_escape = "_EscapeText_" . substitute(&filetype, "[.]", "_", "g")
    if exists("*" . custom_escape)
      let result = call(custom_escape, [a:text])
    end
  end

  " use a:text if the ftplugin didn't kick in
  if !exists("result")
    let result = a:text
  end

  " return an array, regardless
  if type(result) == type("")
    return [result]
  else
    return result
  end
endfunction


function! s:SbshFlashVisualSelection()
  " Redraw to show current visual selection, and sleep
  redraw
  execute "sleep " . g:sbsh_flash_duration . " m"
  " Then leave visual mode
  silent exe "normal! vv"
endfunction


function! s:SbshSendOp(type, ...) abort
  let sel_save = &selection
  let &selection = "inclusive"
  let rv = getreg('"')
  let rt = getregtype('"')

  if a:0  " Invoked from Visual mode, use '< and '> marks.
    silent exe "normal! `<" . a:type . '`>y'
  elseif a:type == 'line'
    silent exe "normal! '[V']y"
  elseif a:type == 'block'
    silent exe "normal! `[\<C-V>`]\y"
  else
    silent exe "normal! `[v`]y"
  endif

  call setreg('"', @", 'V')
  call s:SbshSend(@")

  " Flash selection
  if a:type == 'line'
    silent exe "normal! '[V']"
    call s:SbshFlashVisualSelection()
  endif

  let &selection = sel_save
  call setreg('"', rv, rt)

  call s:SbshRestoreCurPos()
endfunction

function! s:SbshSendRange() range abort
  let rv = getreg('"')
  let rt = getregtype('"')
  silent execute a:firstline . ',' . a:lastline . 'yank'
  call s:SbshSend(@")
  call setreg('"', rv, rt)
endfunction


function! s:SbshSendLines(count) abort
  let rv = getreg('"')
  let rt = getregtype('"')

  silent execute "normal! " . a:count . "yy"

  call s:SbshSend(@")
  call setreg('"', rv, rt)

  " Flash lines
  silent execute "normal! V"
  if a:count > 1
    silent execute "normal! " . (a:count - 1) . "\<Down>"
  endif
  call s:SbshFlashVisualSelection()
endfunction


function! s:SbshStoreCurPos()
  if g:sbsh_preserve_curpos == 1
    if exists("*getcurpos")
      let s:cur = getcurpos()
    else
      let s:cur = getpos('.')
    endif
  endif
endfunction


function! s:SbshRestoreCurPos()
  if g:sbsh_preserve_curpos == 1
    call setpos('.', s:cur)
  endif
endfunction


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Setup key bindings
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

command! -nargs=0 SbshStart call s:SbshStart()
command! -nargs=0 SbshHush call s:SbshSend("hush")

command -range -bar -nargs=0 SbshSend <line1>,<line2> call s:SbshSendRange()
command -nargs=+ SbshSend1 call s:SbshSend(<q-args> . "\r")

noremap <SID>Operator :<c-u>call <SID>SbshStoreCurPos()<cr>:set opfunc=<SID>SbshSendOp<cr>g@

noremap <unique> <script> <silent> <Plug>SbshRegionSend :<c-u>call <SID>SbshSendOp(visualmode(), 1)<cr>
noremap <unique> <script> <silent> <Plug>SbshLineSend :<c-u>call <SID>SbshSendLines(v:count1)<cr>
noremap <unique> <script> <silent> <Plug>SbshMotionSend <SID>Operator
noremap <unique> <script> <silent> <Plug>SbshParagraphSend <SID>Operatorip
