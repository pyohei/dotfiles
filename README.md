# Dot file list

This is my dot file.

## Install

Copies `.zshrc` and `.local/bin` into `$HOME`, the AI instruction files into
`~/.claude` and `~/.codex`, and the Neovim configuration into
`~/.config/nvim`.

```sh
./install.sh -n   # dry run
./install.sh
```

A destination that already differs from the repository is reported and left
alone, so an edit made directly in `$HOME` survives a routine run. Pass `-f`
to let the repository win.

Files this repository no longer tracks are left in place and have to be
removed by hand.

## Neovim

`.config/nvim` needs Neovim 0.12 or later. Plugins are managed by the built-in
`vim.pack` and pinned in `nvim-pack-lock.json`; language servers are installed
by mason on first launch. Both land outside this repository, so only the
configuration is tracked here.

Treesitter parsers are compiled on first launch and need the `tree-sitter` CLI,
which is its own formula -- `brew install tree-sitter-cli`, not `tree-sitter`,
which ships only the library.

To work on the configuration without touching `$HOME`, point `HOME` at the
repository:

```sh
HOME=$PWD nvim
```

Config, data and state then all resolve inside the working tree. Run
`./install.sh` once the result is good.

## Documents

* [pyohei-ai](docs/pyohei-ai.md) -- mint GitHub App installation tokens

## LICENSE

* [MIT](https://github.com/pyohei/vim-setting/blob/master/LICENSE)
