# vim-lsp-naive

> [!WARNING]
> The code in this repository is written completely by AI. No human review applied.

This is a work in progress. A Vim plugin (for personal use) to provide a minimal integration with existing LSP.

## Command

- `:LspConfig` - opens (or creates) `vim-lsp.json` in the user Vim directory.

## Automatic behavior

- On `BufEnter`, plugin reads `vim-lsp.json` and checks `servers` for an entry
  with `filetype` matching current buffer. When found, it prints
  `found <server-object>`.
