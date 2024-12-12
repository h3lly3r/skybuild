let g:SkylarkMessageCache = ""
let g:SkyDebugging = 0

function! SkyDisplayInfo(info)
  let &statusline = "Sky-" . a:info . &statusline
endfunction

function! SkyCacheMsg(msg)
  if !empty(a:msg)
    let g:SkylarkMessageCache = g:SkylarkMessageCache . "-" . a:msg
  endif
endfunction

function! SkyDebug(msg)
  if g:SkyDebugging
    call SkyCacheMsg(a:msg)
  endif
endfunction

function! Skylark_PRINTLINE(line)
" havent found a way to print a message to the user that isnt annoying
" call SkyCacheMsg(a:line)
endfunction

" given an absolute path, for executing a project after its compiled
function! Skylark_EXECUTE(executable)
  execute '!' . shellescape(a:executable)
  call SkyDisplayInfo("ran" . a:executable)
endfunction

function! Skylark_REWRITE(data_and_dest)
  let rewrite = split(a:data_and_dest, '>>')
  execute '!:echo -e "' . rewrite[0] . '" >> ' . shellescape(rewrite[1])
  call SkyDebug('Skylike rewrote ' . rewrite[1])
  call SkyDisplayInfo('>>' . rewrite[1])
endfunction

function! Skylark_CHANGE_DIR(path)
  execute ':cd ' . a:path
  execute ':Ex'
  call SkyDebug('Skylark navigated to project ' . a:path)
  call SkyDisplayInfo(a:path)
endfunction

function! Skylark(...)
  let runtime_itendifier = "[RUNTIME_VIM]"
  let args = join(a:000, ' ')
  call SkyCacheMsg('args ' . args)
  let commands = split(system('~/.skylark/skybuild.sh ' . "[RUNTIME_VIM]" . ' ' . args), '\zs;\ze')
" debugging stuff, uncommend to see the information thats come through  
  "let returneddata = join(commands, ';')
  "if !empty(returneddata)
  "  :call SkyDebug('Skylark call returned ' . returneddata)
  "endif
  let command_dict = {
    \ '[PRINTLINE]' : function('Skylark_PRINTLINE'),
    \ '[EXECUTE]'   : function('Skylark_EXECUTE'),
    \ '[REWRITE]'   : function('Skylark_REWRITE'),
    \ '[CHANGE_DIR]': function('Skylark_CHANGE_DIR')
    \}
  for COMMAND in commands
    let key = matchstr(COMMAND, '\[.*\]')
    call SkyDebug("RECIEVED FROM SKYLARK -- command " . key)
    let arg = matchstr(COMMAND, '-->\zs.*$')
    call SkyDebug(" arg " . arg)
    if has_key(command_dict, key)
      call command_dict[key](arg)
    else
      call SkyCacheMsg("skybuild.sh returned invalid command: " . COMMAND)
    endif
  endfor
  if !empty(g:SkylarkMessageCache) && g:SkyDebugging
    echomsg g:SkylarkMessageCache
    let g:SkylarkMessageCache = ""
  endif
endfunction


command! -nargs=* Skylark call Skylark(<q-args>)
