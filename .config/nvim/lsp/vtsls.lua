-- vtsls rather than typescript-language-server: it is the server Vue's tooling
-- expects when TypeScript and Vue have to share one process.
return {
  cmd = { 'vtsls', '--stdio' },
  filetypes = {
    'javascript', 'javascriptreact', 'typescript', 'typescriptreact',
  },
  root_markers = { 'tsconfig.json', 'jsconfig.json', 'package.json', '.git' },
}
