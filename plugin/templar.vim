" Last Change: 2022 jun 14
" Author: Thomas Vigouroux

if exists('g:loaded_templar')
	finish
else
	let g:loaded_templar = 1
endif

augroup Templar
    autocmd BufNewFile * lua require'templar'.source()
augroup END
