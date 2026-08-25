-- Buffer-local: the old after/ftplugin used :set, which leaked these into
-- every other buffer opened afterwards.
vim.opt_local.expandtab = true
vim.opt_local.shiftwidth = 4
vim.opt_local.softtabstop = 4
-- A literal tab, should one survive, renders at its conventional width.
vim.opt_local.tabstop = 8

-- The old file also set smartindent with a cinwords list. Neovim ships a
-- real python indent plugin, and smartindent fights with it.
