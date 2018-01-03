let [s:context, s:curchar] = ['', '']

let s:regex = {'pair': '[\[\]\{\}()\<\>"`'."']",
            \'open': '[\[\{(\<]',
            \'close': '[\]\}(\>]',
            \'quote': "[\"']",
            \'space': '\s\{2,}',
            \'word': '\w\{2,}',
            \'nonword': '\W\{2,}',
            \'punc': '[:punct:]',
            \}

" replace tabs with spaces so that col('.') - 1 is current char
fun! s:getLine(...)
    let a:line = (a:0) ? (a:1) : '.'
    return substitute(getline(a:line), '\t', ' \{'. &tabstop .'}', 'g')
endfun

fun! s:getContext()
    let a:line = s:getLine()
    let a:len = len(a:line)
    
    if col('.') == 1
        return "\n".strcharpart(a:line, 0, 2)
    elseif col('.') >= a:len
        return strcharpart(a:line, (col('.') - 2), 2)."\n"
    else
        return strcharpart(a:line, (col('.') - 2), 3)
    endif
endfun

fun! s:class(class)
    if (has_key(s:regex, a:class))
        return s:regex[a:class]
    else
        return a:class
   endif
endfun

fun! s:include(class)
    return s:context =~ (s:class(a:class))
endfun

fun! s:char_is(class)
    return s:curchar =~ (s:class(a:class))
endfun

fun! s:context_str(class, ...)
    return matchstr(s:context, s:class(a:class))
endfun

" fun! s:select_WORD_no_paren()
    " exe 'normal! \([\[\(\{]\)\@<=\S\+'
" endfun

fun! AutoSelect()
    let prevline = line('.')
    let prevcol = col('.')
    let s:context = s:getContext()
    let s:context = substitute(s:context, '\\', '~', 'g') " hack so that backslash doesn't break some matches
    let s:curchar = s:context[1]
    let s:prevchar = s:context[0]
    let s:nextchar = s:context[2]
    
    if s:include('pair')
        if s:prevchar =~ (s:class('close'))
            normal viw
        elseif s:nextchar =~ (s:class('open'))
            normal viw
        elseif s:char_is('pair')
            if s:char_is('quote')
                exe 'normal! vi'.s:curchar.'loho'
            else
                exe 'normal! va'.s:curchar
            endif
        else
            exe 'normal! vi'.s:context_str('pair')[0]
        endif
    elseif s:include(',')
        normal! T,v/,\|\>
    elseif s:include('nonword') " contains > 1 consecutive nonword chars
        normal! viW
    elseif s:include('\w[:\-/.]\w')
        normal! viW
    elseif s:include('^/') " path or regex
        normal! vt/
    elseif s:include('/$') " path or regex
        normal! vT/
    elseif s:include('word') " contains > 1 consecutive word chars
        normal viw
    elseif s:char_is('\w') " cursor on wordchar
        normal viw
    elseif s:include('\s')
        if s:nextchar =~ '\w'
            normal! vaw
        else
            normal! viw
        endif
    endif
endfun

nmap <silent> <Plug>AutoSelect :call AutoSelect()<CR>
omap <silent> <Plug>AutoSelect :call AutoSelect()<CR>
