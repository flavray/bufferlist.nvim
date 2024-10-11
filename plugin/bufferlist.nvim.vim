if exists('g:loaded_bufferlist_vim')
  finish
endif

command! -nargs=0 ToggleBufferList lua require("bufferlist-nvim").toggle()

let g:loaded_bufferlist_vim = 1
