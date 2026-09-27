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

-- Space, because the mappings below and the plugin ones further down are all
-- leader-prefixed and backslash is awkward. Must come before any <Leader> map.
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

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

-- Plugins ------------------------------------------------------------------

-- vim.pack is Neovim 0.12's own plugin manager: it clones into the data
-- directory and records revisions in nvim-pack-lock.json next to this file,
-- which is committed. minpac is no longer needed.
vim.pack.add({
  'https://github.com/tpope/vim-fugitive',
  'https://github.com/lewis6991/gitsigns.nvim',
  'https://github.com/nvim-lua/plenary.nvim', -- telescope's dependency
  'https://github.com/nvim-telescope/telescope.nvim',
  'https://github.com/stevearc/oil.nvim',
  'https://github.com/mikavilpas/yazi.nvim',
  -- The default branch is the superseded one; main is the rewrite that
  -- targets Neovim's own treesitter integration.
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter', version = 'main' },
  'https://github.com/mason-org/mason.nvim',
  -- Named, because the repository itself is just called "nvim".
  { src = 'https://github.com/catppuccin/nvim', name = 'catppuccin' },
})

require('gitsigns').setup({
  -- The old configuration set g:gitgutter_highlight_lines.
  linehl = true,
})

-- Replaces ctrlp. find_files and live_grep shell out to fd and rg, both of
-- which are installed.
--
-- Both tools skip dotfiles unless told otherwise, which hides nearly the whole
-- of a dotfiles repository. .git is excluded instead, or it drowns everything
-- else: it holds 331 of the 364 files here.
require('telescope').setup({
  defaults = {
    file_ignore_patterns = { '^%.git/' },
  },
  pickers = {
    find_files = { hidden = true },
    live_grep = { additional_args = { '--hidden' } },
  },
})
local telescope = require('telescope.builtin')
vim.keymap.set('n', '<Leader>f', telescope.find_files, { desc = 'Find files' })
vim.keymap.set('n', '<Leader>g', telescope.live_grep, { desc = 'Grep in project' })
vim.keymap.set('n', '<Leader>b', telescope.buffers, { desc = 'Open buffers' })
vim.keymap.set('n', '<Leader>h', telescope.help_tags, { desc = 'Help tags' })

-- Real parsers instead of the regex highlighting Neovim falls back to, which
-- also gives structural indent. c, lua, markdown, query, vim and vimdoc ship
-- with Neovim, so only the rest are fetched.
require('nvim-treesitter').install({
  'bash', 'css', 'diff', 'gitcommit', 'go', 'gomod', 'html', 'javascript',
  'json', 'python', 'ruby', 'toml', 'tsx', 'typescript', 'yaml',
})

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('TreesitterStart', { clear = true }),
  callback = function(args)
    -- Filetypes whose parser is missing, or not installed yet, keep the
    -- built-in highlighting rather than raising an error.
    if not pcall(vim.treesitter.start, args.buf) then
      return
    end
    vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})

-- Replaces fern. A directory is an ordinary buffer here: rename a file by
-- editing the line and saving.
require('oil').setup({
  -- Off by default, which leaves this repository looking almost empty.
  view_options = { show_hidden = true },
})
vim.keymap.set('n', '-', '<Cmd>Oil<CR>', { desc = 'Open parent directory' })

require('yazi').setup({
  floating_window_scaling_factor = 0.95,
  yazi_floating_window_winblend = 10,
  yazi_floating_window_border = 'single',
  keymaps = { copy_relative_path_to_selected_files = false },
})
vim.keymap.set({ 'n', 'x' }, '<Leader>y', '<Cmd>Yazi<CR>', { desc = 'Open Yazi' })

-- Installs language servers into Neovim's own data directory and puts them on
-- PATH, so they survive fnm switching the active node version. Must run
-- before any server is spawned.
require('mason').setup()

-- The servers themselves land in the data directory, which is machine-local
-- and not committed, so a fresh machine starts without them. Fetch whatever is
-- missing in the background rather than leaving it as a manual step.
--
-- The installed list is read from disk, and the registry -- which is a network
-- call -- is only refreshed when something is actually missing.
-- mason package name -> the executable it is expected to leave behind. An
-- install interrupted partway through still registers as installed but leaves
-- a dangling symlink, so the binary is what actually gets checked.
local servers = {
  ['pyright'] = 'pyright-langserver',
  ['vtsls'] = 'vtsls',
  ['css-lsp'] = 'vscode-css-language-server',
  ['html-lsp'] = 'vscode-html-language-server',
  ['gopls'] = 'gopls',
}

local bin = vim.fn.stdpath('data') .. '/mason/bin/'
local missing = {}
for package, executable in pairs(servers) do
  local path = bin .. executable
  if vim.fn.executable(path) ~= 1 then
    -- A dangling symlink is what an interrupted install leaves behind, and
    -- mason refuses to install over one ("is already linked"), so every later
    -- attempt would fail the same way until it is cleared.
    if vim.uv.fs_lstat(path) then
      vim.uv.fs_unlink(path)
    end
    missing[#missing + 1] = package
  end
end

if #missing > 0 then
  local registry = require('mason-registry')
  registry.refresh(function()
    for _, name in ipairs(missing) do
      vim.notify('mason: installing ' .. name)
      registry.get_package(name):install()
    end
  end)
end

-- Colour scheme -------------------------------------------------------------

vim.cmd.colorscheme('catppuccin')

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
