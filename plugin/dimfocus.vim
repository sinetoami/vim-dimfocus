if exists('g:loaded_diminactive')
  finish
endif
let g:loaded_diminactive = 1

let s:save_cpo = &cpoptions
set cpoptions&vim

if !exists('g:dim_inactive_blacklist')
  let g:dim_inactive_blacklist = ['diff', 'undotree', 'nerdtree', 'qf']
endif

if !exists('g:dim_cursorline_blacklist')
  let g:dim_cursorline_blacklist = ['command-t']
endif

function! dimfocus#should_colorcolumn() abort
  return index(g:dim_inactive_blacklist, &filetype) == -1
endfunction

function! dimfocus#should_cursorline() abort
  return index(g:dim_cursorline_blacklist, &filetype) == -1
endfunction

function! dimfocus#blur_window() abort
  if dimfocus#should_colorcolumn()
    if !exists('w:wincent_matches')
      " Instead of unconditionally resetting, append to existing array.
      " This allows us to gracefully handle duplicate autocmds.
      let w:wincent_matches=[]
    endif
    let l:height=&lines
    let l:slop=l:height / 2
    let l:start=max([1, line('w0') - l:slop])
    let l:end=min([line('$'), line('w$') + l:slop])
    while l:start <= l:end
      let l:next=l:start + 8
      let l:id=matchaddpos(
            \   'Dim',
            \   range(l:start, min([l:end, l:next])),
            \   1000
            \ )
      call add(w:wincent_matches, l:id)
      let l:start=l:next
    endwhile
  endif
endfunction

function! dimfocus#focus_window() abort
  if dimfocus#should_colorcolumn()
    if exists('w:wincent_matches')
      for l:match in w:wincent_matches
        try
          call matchdelete(l:match)
        catch /.*/
          " In testing, not getting any error here, but being ultra-cautious.
        endtry
      endfor
      let w:wincent_matches=[]
    endif
  endif
endfunction

augroup DimFocus
  autocmd!
  hi def Dim cterm=none ctermbg=235 ctermfg=242

  if exists('+colorcolumn')
    autocmd BufEnter,FocusGained,VimEnter,WinEnter * if dimfocus#should_colorcolumn() | let &l:colorcolumn='+1,+2' | endif
    autocmd FocusLost,WinLeave * if dimfocus#should_colorcolumn() | let &l:colorcolumn=join(range(1, 255), ',') | endif
  endif

  autocmd InsertLeave,VimEnter,WinEnter * if dimfocus#should_cursorline() | setlocal cursorline | endif
  autocmd InsertEnter,WinLeave * if dimfocus#should_cursorline() | setlocal nocursorline | endif

  if exists('*matchaddpos')
    autocmd BufEnter,FocusGained,VimEnter,WinEnter * call dimfocus#focus_window()
    autocmd FocusLost,WinLeave * call dimfocus#blur_window()
  endif
augroup END

let &cpoptions = s:save_cpo
