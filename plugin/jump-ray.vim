" Initialize jump-ray module and commands

" prevent loading file twice
if exists("g:loaded_jumpray")
  finish
endif

lua require("jump-ray").init()

let g:loaded_jumpray = 1
