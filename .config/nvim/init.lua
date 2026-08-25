-- Neovim configuration. Options, keymaps and autocommands only; plugins are
-- added separately.
--
-- Anything Neovim already does by default is left out, so what remains here is
-- a deliberate choice rather than a copy of the old vimrc.

-- Encoding -----------------------------------------------------------------

-- Neovim's default list gives up after latin1, which turns Japanese files
-- written in the legacy encodings into mojibake.
vim.opt.fileencodings = {
  'ucs-bom', 'utf-8', 'cp932', 'euc-jp', 'iso-2022-jp', 'default', 'latin1',
}

-- Indent -------------------------------------------------------------------

-- Four spaces. Per-language overrides live in after/ftplugin/.
vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4

-- Display ------------------------------------------------------------------

vim.opt.number = true
vim.opt.cursorline = true
vim.opt.scrolloff = 3
vim.opt.showmatch = true
vim.opt.termguicolors = true
vim.opt.mouse = 'a'

-- Opening or closing a window should not resize the others.
vim.opt.equalalways = false

vim.opt.list = true
vim.opt.listchars = { tab = '^^', extends = '>', precedes = '<', nbsp = '%' }

vim.opt.statusline = table.concat {
  '%F%m%r%h%w%=',
  '[TYPE=%Y][FORMAT=%{&ff}][ENC=%{&fileencoding}][LINE=%l/%L]',
}

-- Search -------------------------------------------------------------------

-- Case-insensitive until the pattern contains an uppercase letter.
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Files --------------------------------------------------------------------

-- Keep undo history across sessions. The old vimrc set undodir but never
-- turned undofile on, so undo died with every :q.
vim.opt.undofile = true

-- Share the system clipboard with unnamed yanks and puts.
vim.opt.clipboard = 'unnamed'

-- Keymaps ------------------------------------------------------------------

-- Too close to other two-key commands to be worth the risk of quitting.
vim.keymap.set('n', 'ZZ', '<Nop>')
vim.keymap.set('n', 'ZQ', '<Nop>')

--- Search for the visual selection literally, the way `*` works on a word.
--- @param forward boolean search downwards rather than upwards
local function search_selection(forward)
  return function()
    local saved = vim.fn.getreg('s')
    -- A Lua callback runs with the selection still active, so the text is
    -- yanked directly; the vimscript original needed gv to get it back.
    vim.cmd('noautocmd normal! "sy')
    -- \V makes the rest of the pattern literal, so punctuation in the
    -- selection is not read as regex.
    local pattern = '\\V' .. vim.fn.escape(vim.fn.getreg('s'), '/\\'):gsub('\n', '\\n')
    vim.fn.setreg('s', saved)

    vim.fn.setreg('/', pattern)
    vim.fn.histadd('search', pattern)
    vim.v.searchforward = forward and 1 or 0
    vim.cmd('normal! n')
  end
end

vim.keymap.set('x', '*', search_selection(true), { desc = 'Search selection forwards' })
vim.keymap.set('x', '#', search_selection(false), { desc = 'Search selection backwards' })

-- Autocommands -------------------------------------------------------------

-- A full-width space is invisible but is a syntax error nearly everywhere, so
-- give it a highlight of its own.
local full_width_space = vim.api.nvim_create_augroup('FullWidthSpace', { clear = true })

local function define_highlight()
  vim.api.nvim_set_hl(0, 'FullWidthSpace', { underline = true, fg = 'Green' })
end

define_highlight()
vim.api.nvim_create_autocmd('ColorScheme', {
  group = full_width_space,
  callback = define_highlight,
})

vim.api.nvim_create_autocmd({ 'VimEnter', 'WinEnter' }, {
  group = full_width_space,
  callback = function()
    -- matchadd() is per window and accumulates, so add it only once. The
    -- existing matches are the thing to check: a w: flag would be copied into
    -- every :split, and the new window would then skip its own matchadd.
    for _, match in ipairs(vim.fn.getmatches()) do
      if match.group == 'FullWidthSpace' then
        return
      end
    end
    vim.fn.matchadd('FullWidthSpace', '　')
  end,
})

-- LSP ----------------------------------------------------------------------

-- Server definitions live in lsp/, one file per server, and are looked up by
-- name. Neovim 0.11 and later has all of this built in; no plugin involved.
vim.lsp.enable({ 'pyright', 'vtsls', 'cssls', 'html', 'gopls' })

-- Diagnostics are signs and underlines by default. Show the message inline as
-- well, so a problem does not need a cursor hover to be read.
vim.diagnostic.config({
  virtual_text = { current_line = false },
  severity_sort = true,
})

-- Almost everything is mapped already: K hovers, grn renames, gra runs a code
-- action, grr lists references, gri implementations, grt the type definition,
-- gO document symbols, [d and ]d step through diagnostics and CTRL-W d opens
-- the message under the cursor.
--
-- Definition is reachable through CTRL-] because the LSP sets 'tagfunc', but
-- gd is the reflex. It shadows the built-in "go to local declaration".
vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { desc = 'Go to definition' })
