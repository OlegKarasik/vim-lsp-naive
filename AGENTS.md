# Rules

These rules govern AI-agent workflow in this repository and define
cross-repository plugin API conventions where explicitly stated.

1. DO NOT create or edit files outside of repository.
2. DO NOT redirect output from commands into files outside of repository.
3. DO NOT add or take dependencies on other plugins.
4. DO NOT introduce fallback behavior when a canonical interaction path is defined (for example, if popup UI is used, do not add a list/inputlist fallback).
5. Every public user-facing Ex command must expose a `<Plug>(...)` mapping target.
6. Plugin startup mapping registration must not override an existing `<Plug>(...)` mapping with the same left-hand side.
7. In tests only, any single time-based wait/check interval must not exceed 90 seconds.
8. Every update to plugin functionality must be reflected to its wiki.
9. These global core rules override conflicting local core rules for AI-agent workflow.
10. Global asynchronous rules in `global-async-rules.txt` (umbrella root) are mandatory and override conflicting local async rules.

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
   `vim_lsp_naive#config()`. Registration is non-overriding: existing mapping
   with the same left-hand side is preserved.
4. Registers `BufEnter` autocommand which calls
   `vim_lsp_naive#on_buf_enter(<abuf>)`.
5. Registers `VimLeavePre` autocommand which calls
   `vim_lsp_naive#on_vim_leave()`.

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

## BufEnter Server Lookup

On each `BufEnter`, the plugin:

1. Resolves current buffer filetype.
2. Reads `<user-vim-dir>/vim-lsp.json` when present and non-empty.
3. Reads `servers` property from decoded JSON object.
4. Iterates `servers` list and finds the first object where `filetype` equals
   current buffer filetype.
5. Reads `executable` from matched server entry.
6. If `executable` is missing/empty, stops lookup without starting a job.
7. If `executable` exists and a tracked job for it is running, does nothing.
8. Otherwise starts a new job for `executable`, establishes a channel, captures
   stdout/stderr via callbacks, and stores job+channel in an internal job map.
9. Removes the stored job record when exit callback is triggered.
10. Exits silently when config/servers/filetype data is missing or unmatched.

## VimLeave Job Cleanup

On `VimLeavePre`, the plugin:

1. Copies internal executable->job map.
2. Clears internal map to prevent stale state and callback races.
3. Stops every still-running tracked job via `job_stop(..., 'kill')`.

# Plug Mappings

1. `<Plug>(LspConfig)`
2. Startup registration is non-overriding and keeps pre-existing
   `<Plug>(LspConfig)` mapping.

# Public Vimscript Functions

## `vim_lsp_naive#config()`

Public entry point used by `:LspConfig` and `<Plug>(LspConfig)`.

## `vim_lsp_naive#on_buf_enter(bufnr)`

Public entry point used by `BufEnter` autocommand for per-buffer server lookup.

## `vim_lsp_naive#on_vim_leave()`

Public entry point used by `VimLeavePre` autocommand for shutdown job cleanup.
