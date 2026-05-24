# vim-lsp-naive

> [!WARNING]
> The code in this repository is written completely by AI. No human review applied.

This is a work in progress. A Vim plugin (for personal use) to provide a minimal integration with existing LSP.

## Command

- `:LspConfig` - opens (or creates) `vim-lsp.json` in the user Vim directory.

## Automatic behavior

- On `BufEnter`, plugin reads `vim-lsp.json` and checks `servers` for an entry
  with `filetype` matching current buffer. If that server has `executable`,
  plugin checks internal running jobs for the same executable, and starts a new
  job only when one is not already running. Started jobs are tracked with their
  channels and pipe stdin/stdout/stderr for future communication.
- On `VimLeavePre`, plugin stops all tracked running server jobs to terminate
  spawned processes before Vim exits.
