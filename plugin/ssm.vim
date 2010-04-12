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
	if !exists(a:opt) | let {a:opt} = a:val | endif
    endfunction

    call s:defopt('g:ssm_autostart', 1)
    call s:defopt('g:ssm_snipdir', 'snippets')

    delfunc s:defopt

    " commands & menus {{{2

    command! -bar StartSSM call s:start_ssm()
    command! -bar StopSSM call s:stop_ssm()
    command! -nargs=* SnippetExpand call s:call(s:expand_snippet(), [])

    " small functions {{{2
    let s:sfile = expand('<sfile>')

    function! s:start_ssm() " {{{3
    endfunction
    function! s:stop_ssm() " {{{3
    endfunction
    function! s:call() " {{{3
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


" ============================================================
" File I/O cache functions {{{1

" Snippet managment functions {{{1

" Completion & modify functions {{{1

" ======================================================{{{1

let &cpo = s:cpo_save
unlet s:cpo_save

" vim: ff=unix ft=vim fdm=marker sw=4 ts=8 et sta nu
