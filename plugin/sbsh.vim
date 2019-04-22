if exists("g:loaded_sbsh") || &cp || v:version < 700
  finish
endif
let g:loaded_sbsh = 1

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Tmux
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! s:TmuxSend(config, text)
  let l:prefix = "tmux -L " . shellescape(a:config["socket_name"])
  " use STDIN unless configured to use a file
  if !exists("g:sbsh_paste_file")
    call system(l:prefix . " load-buffer -", a:text)
  else
    call s:WritePasteFile(a:text)
    call system(l:prefix . " load-buffer " . g:sbsh_paste_file)
  end
  call system(l:prefix . " paste-buffer -d -t " . shellescape(a:config["target_pane"]))
endfunction

function! s:TmuxPaneNames(A,L,P)
  let format = '#{pane_id} #{session_name}:#{window_index}.#{pane_index} #{window_name}#{?window_active, (active),}'
  return system("tmux -L " . shellescape(b:sbsh_config['socket_name']) . " list-panes -a -F " . shellescape(format))
endfunction

function! s:TmuxConfig() abort
  if !exists("b:sbsh_config")
    let b:sbsh_config = {"socket_name": "default", "target_pane": ":"}
  end

  let b:sbsh_config["socket_name"] = input("tmux socket name: ", b:sbsh_config["socket_name"])
  let b:sbsh_config["target_pane"] = input("tmux target pane: ", b:sbsh_config["target_pane"], "custom,<SNR>" . s:SID() . "_TmuxPaneNames")
  if b:sbsh_config["target_pane"] =~ '\s\+'
    let b:sbsh_config["target_pane"] = split(b:sbsh_config["target_pane"])[0]
  endif
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Helpers
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! s:SID()
  return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfun

function! s:WritePasteFile(text)
  " could check exists("*writefile")
  call system("cat > " . g:sbsh_paste_file, a:text)
endfunction

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

function! s:SbshGetConfig()
  if !exists("b:sbsh_config")
    if exists("g:sbsh_default_config")
      let b:sbsh_config = g:sbsh_default_config
    else
      call s:SbshDispatch('Config')
    end
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
  call s:SbshGetConfig()

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
  call s:SbshGetConfig()

  let rv = getreg('"')
  let rt = getregtype('"')
  silent execute a:firstline . ',' . a:lastline . 'yank'
  call s:SbshSend(@")
  call setreg('"', rv, rt)
endfunction

function! s:SbshSendLines(count) abort
  call s:SbshGetConfig()

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

let s:parent_path = fnamemodify(expand("<sfile>"), ":p:h:s?/plugin??")

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Public interface
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! s:SbshSend(text)
  call s:SbshGetConfig()

  let pieces = s:_EscapeText(a:text)
  for piece in pieces
    call s:SbshDispatch('Send', b:sbsh_config, piece)
  endfor
endfunction

function! s:SbshConfig() abort
  call inputsave()
  call s:SbshDispatch('Config')
  call inputrestore()
endfunction

" delegation
function! s:SbshDispatch(name, ...)
  let target = substitute(tolower(g:sbsh_target), '\(.\)', '\u\1', '') " Capitalize
  return call("s:" . target . a:name, a:000)
endfunction

function! s:SbshHush()
  execute 'SbshSend1 hush'
endfunction

function! s:SbshSilence(stream)
  silent execute 'SbshSend1 d' . a:stream . ' silence'
endfunction

function! s:SbshPlay(stream)
  let res = search('^\s*d' . a:stream)
  if res > 0
    silent execute "normal! vip:SbshSend\<cr>"
    silent execute "normal! vip"
    call s:SbshFlashVisualSelection()
  else
    echo "d" . a:stream . " was not found"
  endif
endfunction

function! s:SbshGenerateCompletions(path)
  let l:exe = s:parent_path . "/bin/generate-completions"
  let l:output_path = s:parent_path . "/.dirt-samples"

  if !empty(a:path)
    let l:sample_path = a:path
  else
    if has('macunix')
      let l:sample_path = "~/Library/Application Support/SuperCollider/downloaded-quarks/Dirt-Samples"
    elseif has('unix')
      let l:sample_path = "~/.local/share/SuperCollider/downloaded-quarks/Dirt-Samples"
    endif
  endif
  " generate completion file
  silent execute '!' . l:exe shellescape(expand(l:sample_path)) shellescape(expand(l:output_path))
  echo "Generated dictionary of dirt-samples"
  " setup completion
  let &l:dictionary .= ',' . l:output_path
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Setup key bindings
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

command -bar -nargs=0 SbshConfig call s:SbshConfig()
command -range -bar -nargs=0 SbshSend <line1>,<line2>call s:SbshSendRange()
command -nargs=+ SbshSend1 call s:SbshSend(<q-args> . "\r")

command! -nargs=0 SbshHush call s:SbshHush()
command! -nargs=1 SbshSilence call s:SbshSilence(<args>)
command! -nargs=1 SbshPlay call s:SbshPlay(<args>)
command! -nargs=? SbshGenerateCompletions call s:SbshGenerateCompletions(<q-args>)

noremap <SID>Operator :<c-u>call <SID>SbshStoreCurPos()<cr>:set opfunc=<SID>SbshSendOp<cr>g@

noremap <unique> <script> <silent> <Plug>SbshRegionSend :<c-u>call <SID>SbshSendOp(visualmode(), 1)<cr>
noremap <unique> <script> <silent> <Plug>SbshLineSend :<c-u>call <SID>SbshSendLines(v:count1)<cr>
noremap <unique> <script> <silent> <Plug>SbshMotionSend <SID>Operator
noremap <unique> <script> <silent> <Plug>SbshParagraphSend <SID>Operatorip
noremap <unique> <script> <silent> <Plug>SbshConfig :<c-u>SbshConfig<cr>

""
" Default options
"
if !exists("g:sbsh_target")
  let g:sbsh_target = "tmux"
endif

if !exists("g:sbsh_paste_file")
  let g:sbsh_paste_file = tempname()
endif

if !exists("g:sbsh_default_config")
  let g:sbsh_default_config = { "socket_name": "default", "target_pane": ":0.1" }
endif

if !exists("g:sbsh_preserve_curpos")
  let g:sbsh_preserve_curpos = 1
end

if !exists("g:sbsh_flash_duration")
  let g:sbsh_flash_duration = 150
end

if filereadable(s:parent_path . "/.dirt-samples")
  let &l:dictionary .= ',' . s:parent_path . "/.dirt-samples"
endif
