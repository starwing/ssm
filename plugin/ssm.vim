" Script Nmame: Super SnipMate
" File Name:    ssm.vim
" Maintainer:   StarWing
" Version:      0.1
" Last Change:  2010-04-11 15:46:56
" Note:         see :h ssm for details
" ======================================================{{{1

if v:version < 700
    echomsg "ssm.vim requires Vim 7.0 or above."
    finish
endif

let s:cpo_save = &cpo
set cpo&vim

scriptencoding utf-8

if !exists('g:loaded_ssm')
    " =================================================={{{2
    let g:loaded_ssm = 'v0.1'

    " options {{{2
    function! s:defopt(opt, val)
        if !exists(a:opt) | let {a:opt} = a:val | return 1 | endif
    endfunction

    let s:default_keymap = {
                \ 'Expand': '<tab>',
                \ 'JumpForward': '<M-l>',
                \ 'JumpBackward': '<M-h>',
                \ 'JumpPrevLine': '<M-j>',
                \ 'JumpNextLine': '<M-k>',
                \ }

    call s:defopt('g:ssm_autostart', 1)
    call s:defopt('g:ssm_snipdir', 'snippets')

    if !s:defopt('g:ssm_keymap', s:default_keymap)
        for [key, val] in items(s:default_keymap)
            if !has_key(g:ssm_keymap, key)
                let g:ssm_keymap[key] = val
            endif
        endfor
    endif

    unlet s:default_keymap
    delfunc s:defopt

    " commands & menus {{{2

    command! -bar StartSSM call s:start_ssm()
    command! -bar StopSSM call s:stop_ssm()
    command! -bar RefreshSSM unlet! b:ssm_info | call s:call('s:init_bufdata', [])
    command! -bar -nargs=1 EditSnippetFile call s:call('s:show_editlist', [<q-args>])
    command! -nargs=* SnippetExpand call s:call(s:expand_snippet(), [])
    command! -count=0 SnippetJump call s:call(s:expand_snippet(), [<count>])

    imap <Plug>SSMExpand <c-r>=s:expand_snippet()<cr>
    vmap <Plug>SSMExpand "zc<Plug>SSMExpand
    imap <Plug>SSMJumpForward <c-r>=s:jump_tag(1)<cr>
    vmap <Plug>SSMJumpForward "zc<Plug>SSMJumpForward
    imap <Plug>SSMJumpBackward <c-r>=s:jump_tag(-1)<cr>
    vmap <Plug>SSMJumpBackward "zc<Plug>SSMJumpBackward
    imap <Plug>SSMJumpPervLine <c-r>=s:jump_line(-1)<cr>
    vmap <Plug>SSMJumpPervLine "zc<Plug>SSMJumpPervLine
    imap <Plug>SSMJumpNextLine <c-r>=s:jump_line(1)<cr>
    vmap <Plug>SSMJumpNextLine "zc<Plug>SSMJumpNextLine

    " small functions {{{2
    let s:sfile = expand('<sfile>')

    function! s:start_ssm() " {{{3
        augroup ssm_autocmds
            au!
            au FileType *.{snippet,snippets} setf snippet
            au FileType,BufNewFile,BufReadPost,VimEnter *
                        \ call s:call('s:init_bufdata', [0])
            au CursorMovedI * call s:call('s:on_cursor', [])
        augroup END

    endfunction
    function! s:stop_ssm() " {{{3
        au! ssm_autocmds
    endfunction
    function! s:call(func, args) " {{{3
        if !exists('s:load_all')
            exec 'so '.s:sfile
        endif
        return call(a:func, a:args)
    endfunction
    function! s:echoerr(msg) " {{{3
    endfunction " }}}3

    " =================================================={{{2
    if g:ssm_autostart
        StartSSM
    else
        let &cpo = s:cpo_save
        unlet s:cpo_save

        finish
    endif " }}}2
endif

let s:load_all = 1

" some inner variables {{{1

let s:snippets = {}

" ============================================================
" Standard SSM library functions {{{1

function! ssm:let(var, val) " {{{2
    let {var} = val
endfunction " }}}2

" File I/O cache functions {{{1

function! s:init_bufdata(force) " {{{2
    " init per-buffer data, using specfied filetype
    if &ft ==? 'decho' | return | endif
    call Dfunc('s:init_bufdata')

    let b:ssm_info = {}
    let ft = &ft == '' ? '_' : &ft

    call s:update_cache(ft, a:force, [])

    call Dret('s:init_bufdata')
endfunction

function! s:update_cache(filetype, force, blacklist) " {{{2
    " update specfied filetype cache
    call Dfunc('s:update_cache('.a:filetype.', '.a:force.', '.string(a:blacklist).')')

    if a:force || !has_key(s:snippets, a:filetype)
        let s:snippets[a:filetype] = {}
    endif
    let include_ft = []

    for path in split(globpath(&rtp, g:ssm_snipdir), "\n")
        call Decho('path = '.path)
        if path == '' | continue | endif

        let cache_file = path.'/cache/'.a:filetype.'.dat'
        call Decho("read cache file from ".cache_file)
        try
            let cache = eval(join(readfile(cache_file), ""))
        catch 
            let cache = {}
            call Decho("exception in read cache: ".v:exception)
        endtry

        let updated = 0

        " check cache file
        for file in s:get_filelist(path, a:filetype)
            if getftime(file) != get(get(cache, file, {}), 'ftime', -1)
                let updated = 1
                let cache[file] = s:read_snipfile(file)
            endif
        endfor

        " write cache file
        if updated
            call Decho("write cache file to ".cache_file)
            try
                if !isdirectory(path."/cache")
                    call mkdir(path."/cache")
                endif
                " call writefile([s:escape_struct(cache)], cache_file)
            catch
                call Decho("exception in write cache: ".v:exception)
            endtry
        endif

        call Decho("cache = ".string(cache))
        " update s:snippets
        " info == [ftime, include_ft, functions, snippets]
        for [fname, info] in items(cache)
            call extend(include_ft, info[1])

            " exec functions
            for [sign, body] in info[2]
                call Decho('run function['.sign.']['.body.']')
                silent! exec 'function! '.sign."\n".body."endfunction"
            endfor

            " add snippets
            for [key, val] in items(info[3])
                let s:snippets[a:filetype][key] = val
                " XXX: don't support multi snippet name now.
                " if !has_key(s:snippets[a:filetype], key)
                "     let s:snippets[a:filetype][key] = val
                " elseif type(s:snippets[a:filetype][key]) == type([])
                "     call add(s:snippets[a:filetype][key], val)
                " else
                "     let s:snippets[a:filetype][key] = [
                "                 \ s:snippets[a:filetype], val]
                " endif
            endfor
        endfor
    endfor

    " process included filetype
    let blacklist = add(a:blacklist, a:filetype)
    for ft in include_ft
        if !index(blacklist, ft)
            call add(blacklist, ft)
            call s:update_cache(ft, a:force, blacklist)
        endif
    endfor

    call Dret('s:update_cache')
endfunction

function! s:escape_struct(struct, ...) " {{{2
    " convert struct to string, makes it can be eval() back

    let level = a:0 ? a:1 : 10

    if type(a:struct) == type([])
        if level <= 0 | return "[...]" | endif
        let list = []
        for item in a:struct
            call add(list, s:escape_struct(item, level - 1))
            unlet item
        endfor
        return "[".join(list, ", ")."]"

    elseif type(a:struct) == type({})
        if level <= 0 | return "{...}" | endif
        let list = []
        for [key, val] in sort(items(a:struct), 's:dict_compare')
            call add(list, s:escape_struct(key, level - 1).": ".
                        \ s:escape_struct(val, level - 1))
            unlet key val
        endfor
        return "{".join(list, ", ")."}"

    elseif type(a:struct) == type('')
        return '"'.substitute(substitute(escape(a:struct, '"\'),
                    \ '\n', '\\n', 'g'), '\t', '\\t', 'g').'"'
    else
        return string(a:struct)
    endif
endfunction

function! s:dict_compare(lhs, rhs) " {{{2
    return a:lhs[0] == a:rhs[0] ? 0 : a:lhs[0] > a:rhs[0] ? 1 : -1
endfunction

function! s:get_filelist(path, filetype) " {{{2
    let flist = s:get_snipfiles(a:path."/".a:filetype)

    for file in split(glob(a:path."/".a:filetype.'[.-_]*'), "\n")
        if !isdirectory(file)
            let extname = fnamemodify(file, ":e")
            if extname ==? 'snippet' || extname ==? 'snippets'
                call add(flist, file)
            endif
        else
            call extend(flist, s:get_snipfiles(file))
        endif
    endfor

    return flist
endfunction

function! s:get_snipfiles(path) " {{{2
    let flist = split(glob(a:path."/*.snippet"), "\n")
                \ + split(glob(a:path."/*.snippets"), "\n")

    for file in split(glob(a:path."/*"), "\n")
        if isdirectory(file)
            call extend(flist, s:get_allsnipfile(file)
        endif
    endfor

    return flist
endfunction

function! s:read_snipfile(fname, ...) " {{{2
    call Dfunc('s:read_snipfile('.a:fname.', '.string(a:000).')')

    if !a:0 || type(a:1) != type({})
        let info = {'path': fnamemodify(a:fname, ":p:h"),
                    \ 'blacklist': [],
                    \ 'include_ft': [],
                    \ 'snippets': {},
                    \ 'functions': []}
    else
        let info = a:1
        let info.path = fnamemodify(a:fname, ":p:h")
    endif

    let none = s:snipfile.none
    let current = none.begin(info)

    for line in readfile(a:fname)
        cal Decho('current.text = '.string(current.text))
        if line[0] == "\t" " text
            let current.text .= line[1:]."\n"

        elseif line == '' || line[0] == "#" || line[0] == '"'
            " ignore the empty line (not blank line!) and comment

        else " exit previous section
            call current.end(info)

            let info.line = matchlist(line, '\v^(\w+)\s+(.{-})\s*%(["#].*)=$')

            call Decho("a new ".info.line[1]." section: ".info.line[2])
            let current = get(s:snipfile, info.line[1], none).begin(info)
            let current.text = ''
        endif
    endfor
    call current.end(info)

    call Dret('s:read_snipfile')
    return [getftime(a:fname), info.include_ft, info.functions, info.snippets]
endfunction

" snipfile object " {{{2

let s:snipfile = {
            \ 'source': {},
            \ 'require': {},
            \ 'function': {},
            \ 'snippet': {},
            \ 'none': {},
            \ }

function! s:snipfile.none.begin(info) dict " {{{3
    let self.text = ''
    return self
endfunction

function! s:snipfile.none.end(info) dict " {{{3
    " do nothing
endfunction

function! s:snipfile.snippet.begin(info) dict " {{{3
    let self.snippet_name = split(a:info.line[2])[0]
    let self.info = {}
    call substitute(a:info.line[2], '++\v(\w+)\s*\=\s*(\S)(.{-})\2',
                \ '\=ssm:let("self.info[submatch(1)]", "submatch(3)")', 'g')
    return self
endfunction

function! s:snipfile.snippet.end(info) dict " {{{3
    let a:info.snippets[self.snippet_name] =
                \ s:ref_to_idx(s:parse_snippet(self.text, self.info))
endfunction

function! s:snipfile.function.begin(info) dict " {{{3
    let self.function_signature = a:info.line[2]
    return self
endfunction

function! s:snipfile.function.end(info) dict " {{{3
    call add(a:info.functions, [self.function_signature, self.text])
endfunction

function! s:snipfile.require.begin(info) dict " {{{3
    for ft in split(a:info.line[2], "\s*,\s*")
        if !index(a:info.include_ft, ft)
            call add(a:info.include_ft, ft)
        endif
    endfor
endfunction

function! s:snipfile.require.end(info) dict " {{{3
endfunction

function! s:snipfile.source.begin(info) dict " {{{3
    if filereadable(a:info.line[2])
        let fname = a:info.line[2]
    elseif filereadable(a:info.path.'/'.a:info.line[2])
        let fname = a:info.path.'/'.a:info.line[2]
    else
        return self
    endif

    if !index(a:info.blacklist, fname)
        call add(a:info.blacklist, fname)
        call s:read_snipfile(fname, a:info)
    endif
endfunction

function! s:snipfile.source.end(info) dict " {{{3
    " do nothing
endfunction " }}}3

" }}}2

" Snippet managment functions {{{1

function! s:parse_snippet(text, info) " {{{2
endfunction

function! s:ref_to_idx(snip) " {{{2
endfunction

function! s:idx_to_ref(snip) " {{{2
endfunction " }}}2

" Completion & modify functions {{{1

function! s:on_cursor() " {{{2
endfunction " }}}2

" ======================================================{{{1

let &cpo = s:cpo_save
unlet s:cpo_save

" vim: ff=unix ft=vim fdm=marker sw=4 ts=8 et sta nu
