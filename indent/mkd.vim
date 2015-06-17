if exists("b:did_indent") | finish | endif
let b:did_indent = 1

setlocal indentexpr=GetMkdIndent()
setlocal nolisp
setlocal autoindent

" Only define the function once
if exists("*GetMkdIndent") | finish | endif

function! s:is_li_start(line)
    return a:line !~ '^ *\([*-]\)\%( *\1\)\{2}\%( \|\1\)*$' &&
      \    (a:line =~ '^\s*[*+-]\s\+' || a:line =~ '^\s*\d\+\.\s\+')
endfunction

function! s:is_blank_line(line)
    return a:line =~ '^$'
endfunction

function! s:prevnonblank(lnum)
    let i = a:lnum
    while i > 1 && s:is_blank_line(getline(i))
        let i -= 1
    endwhile
    return i
endfunction

function! s:needs_increasing(clnum, plnum)
    " Last line is the first line of a list item, increase indent
    let cline = getline(a:clnum) " Current line
    let pline = getline(a:plnum) " Previous line
    return !s:is_li_start(cline) && s:is_li_start(pline) && a:clnum - a:plnum < 3
endfunction

function! s:needs_keeping(clnum, plnum)
    let pline = getline(a:plnum)
    if a:plnum == 0
        return 0
    elseif a:clnum - a:plnum >= 3
        return 0
    elseif s:is_li_start(pline)
        return 1
    else
        return s:needs_keeping(a:plnum, prevnonblank(a:plnum - 1))
    endif
endfunction

function GetMkdIndent()
    let list_ind = 4
    " Find a non-blank line above the current line.
    let lnum = prevnonblank(v:lnum - 1)
    " At the start of the file use zero indent.
    if lnum == 0 | return 0 | endif
    let ind = indent(lnum)
    let line = getline(lnum)    " Last line
    let cline = getline(v:lnum) " Current line
    if s:is_li_start(cline) 
        " Current line is the first line of a list item, do not change indent
        return indent(v:lnum)
    elseif v:lnum - lnum == 1
        return indent(v:lnum)
    elseif s:needs_increasing(v:lnum, lnum)
        return ind + list_ind
    elseif s:needs_keeping(v:lnum, lnum)
        return ind
    else
        return 0
    endif
endfunction
