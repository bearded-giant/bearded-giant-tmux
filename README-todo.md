# Todo chip for Bearded Giant Tmux

Bearded Giant can show your current [doit](https://github.com/bearded-giant/doit) todo in the status bar. The chip itself belongs to doit; this theme only knows how to find it.

## How the pieces fit

doit ships a tmux plugin with a status module (`tmux/status/todo.sh`) and the scripts behind it (`tmux/scripts/`). When `todo` appears in your status modules, the theme's module loader looks in `custom/` first, then in the installed doit plugin (`~/.config/tmux/plugins/doit/tmux/status` or `~/.tmux/plugins/doit/tmux/status`; a clone from before the repo was renamed to `doit` sits under `do-it.nvim` and is found too), then in this theme's own `status/` and `window/` directories. The first hit wins, so the doit module is what renders. Nothing todo-related lives in this repo.

Each tmux window can be linked to its own list, so worktrees opened as windows of one session keep separate todos. The chip resolves the list per window: an explicit `DOIT_ACTIVE_LIST` environment variable wins, then the window's link, then `daily`. A window with no link always shows `daily`, and that list is created on first use if it is missing. The link lives on the window as a tmux option, so it survives renaming or moving the window, and doit saves a copy by `<session>:<window>` name that comes back after a tmux restart. Link a window from the doit list switcher (`prefix + d, l`), the list manager (`prefix + d, L`), from Neovim, or through the MCP server.

## What you see

| State | Chip text |
|---|---|
| A todo is in progress on the window's list | `<session>:<window>: <todo>`, the todo text cut at 25 characters, colored by priority |
| Nothing in progress | `<session>:<window>: no active` in the idle color |

The `<session>:<window>` label is shown whole; cap it with `set -g @doit-list-chars "N"`. Widen or narrow the todo text with `set -g @doit-todo-chars "N"`.

## Setup

1. Install both plugins with TPM and add `todo` to the right-hand modules:

   ```tmux
   set -g @plugin 'bearded-giant/bearded-giant-tmux'
   set -g @plugin 'bearded-giant/doit'
   set -g @bearded_giant_status_modules_right "meetings todo"
   ```

2. Install `jq` (required) and `fzf` (for the interactive manager).
3. Reload tmux with `prefix + r` or `tmux source-file ~/.config/tmux/tmux.conf`.

Keybindings (`prefix + d` followed by a key, or the `Alt+Shift` shortcuts) are defined in doit's `tmux/doit.tmux`. Its README has the full list.

## Troubleshooting

1. Confirm the theme found the doit scripts: `tmux showenv -g DOIT_SCRIPTS_DIR` should print the plugin's `tmux/scripts` path.
2. Run the chip script by hand for a window: `~/.config/tmux/plugins/doit/tmux/scripts/todo-exec.sh '<session>:<window>'`. It prints exactly what the status bar would show for that window.
3. Check the link map under the `sessions` key in `~/.local/share/nvim/doit/session.json` (keys are `<session>:<window>`) and the list files in `~/.local/share/nvim/doit/lists/`.
4. Check `which jq`.
