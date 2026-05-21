# Rules

These rules govern AI-agent workflow in this repository and do not define or
constrain plugin runtime functionality.

1. DO NOT create or edit files outside of repository.
2. DO NOT redirect output from commands into files outside of repository.
3. DO NOT add or take dependencies on other plugins.
4. DO NOT introduce fallback behavior when a canonical interaction path is defined (for example, if popup UI is used, do not add a list/inputlist fallback).
5. In tests only, any single time-based wait/check interval must not exceed 90 seconds.
6. Every update to plugin functionality must be reflected to its wiki.
7. These global core rules override conflicting local core rules for AI-agent workflow.
8. Global asynchronous rules in `global-async-rules.txt` (umbrella root) are mandatory and override conflicting local async rules.

## Core Docs

1. Global constraints only: `agents/core/rules.md`.

# Shared Popup Rules Copy

1. Shared cross-repository popup rules are copied in `agents/ui/popups-shared.md`.
2. This plugin currently has no popup UI implementation; the copied rules are kept for consistency.

# Startup

During startup (`plugin/vim_lsp_naive.vim`), the plugin:

1. Uses `g:loaded_vim_lsp_naive` guard to avoid double loading.
2. Registers command: `:LspConfig`.
3. Registers mapping target: `<Plug>(LspConfig)` which calls
   `vim_lsp_naive#config()`.
4. Registers `BufReadPost` autocommand which calls
   `vim_lsp_naive#on_buf_read_post(<abuf>)`.

# Command

## LspConfig

Execution flow:

1. Resolves user Vim directory by platform:
   1. Windows: `~/vimfiles`
   2. Linux/macOS: `~/.vim`
2. Creates user Vim directory when missing.
3. Creates `<user-vim-dir>/vim-lsp.json` with `{}` when missing.
4. Opens configuration file in current window.

# Automatic Behavior

## BufReadPost Server Lookup

On each `BufReadPost`, the plugin:

1. Resolves current buffer filetype.
2. Reads `<user-vim-dir>/vim-lsp.json` when present and non-empty.
3. Reads `servers` property from decoded JSON object.
4. Iterates `servers` list and finds the first object where `filetype` equals
   current buffer filetype.
5. Prints `found <object>` via `:echomsg` when match is found.
6. Exits silently when config/servers/filetype data is missing or unmatched.

# Plug Mappings

1. `<Plug>(LspConfig)`

# Public Vimscript Functions

## `vim_lsp_naive#config()`

Public entry point used by `:LspConfig` and `<Plug>(LspConfig)`.

## `vim_lsp_naive#on_buf_read_post(bufnr)`

Public entry point used by `BufReadPost` autocommand for per-buffer server lookup.
