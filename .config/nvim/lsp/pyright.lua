-- Server definitions are picked up by name from this directory; init.lua only
-- has to list which ones to enable.
return {
  cmd = { 'pyright-langserver', '--stdio' },
  filetypes = { 'python' },
  root_markers = {
    'pyproject.toml', 'setup.py', 'setup.cfg', 'requirements.txt',
    'Pipfile', 'pyrightconfig.json', '.git',
  },
  settings = {
    python = {
      analysis = {
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
        -- Whole-project analysis is slow on anything large.
        diagnosticMode = 'openFilesOnly',
      },
    },
  },
}
