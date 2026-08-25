-- Buffer-local: the old after/ftplugin used :set, which leaked these into
-- every other buffer opened afterwards.
vim.opt_local.expandtab = true
vim.opt_local.shiftwidth = 2
vim.opt_local.softtabstop = 2
-- A literal tab, should one survive, renders at its conventional width.
vim.opt_local.tabstop = 8
