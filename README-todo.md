# Todo chip for Bearded Giant Tmux

Bearded Giant can show your current [Do-It.nvim](https://github.com/bearded-giant/do-it.nvim) todo in the status bar. The chip itself belongs to Do-It.nvim; this theme only knows how to find it.

## How the pieces fit

Do-It.nvim ships a tmux plugin with a status module (`tmux/status/todo.sh`) and the scripts behind it (`tmux/scripts/`). When `todo` appears in your status modules, the theme's module loader looks in `custom/` first, then in the installed Do-It.nvim plugin (`~/.config/tmux/plugins/do-it.nvim/tmux/status` or `~/.tmux/plugins/do-it.nvim/tmux/status`), then in this theme's own `status/` and `window/` directories. The first hit wins, so the Do-It.nvim module is what renders. Nothing todo-related lives in this repo.

Each tmux session can be linked to its own list. The chip resolves the list per session: an explicit `DOIT_ACTIVE_LIST` environment variable wins, then the session's link, then `daily`. A session with no link always shows `daily`, and that list is created on first use if it is missing. Link a session from the Do-It.nvim list switcher (`prefix + d, l`), the list manager (`prefix + d, L`), from Neovim, or through the MCP server.

## What you see

| State | Chip text |
|---|---|
| A todo is in progress on the session's list | `<list>: <todo>`, the todo text cut at 25 characters, colored by priority |
| Nothing in progress | `<list>: no active` in the idle color |

The list name is cut at 10 characters with an ellipsis; change that with `set -g @doit-list-chars "N"`.

## Setup

1. Install both plugins with TPM and add `todo` to the right-hand modules:

   ```tmux
   set -g @plugin 'bearded-giant/bearded-giant-tmux'
   set -g @plugin 'bearded-giant/do-it.nvim'
   set -g @bearded_giant_status_modules_right "meetings todo"
   ```

2. Install `jq` (required) and `fzf` (for the interactive manager).
3. Reload tmux with `prefix + r` or `tmux source-file ~/.config/tmux/tmux.conf`.

Keybindings (`prefix + d` followed by a key, or the `Alt+Shift` shortcuts) are defined in Do-It.nvim's `tmux/doit.tmux`. Its README has the full list.

## Troubleshooting

1. Confirm the theme found the Do-It.nvim scripts: `tmux showenv -g DOIT_SCRIPTS_DIR` should print the plugin's `tmux/scripts` path.
2. Run the chip script by hand for a session: `~/.config/tmux/plugins/do-it.nvim/tmux/scripts/todo-exec.sh '<session name>'`. It prints exactly what the status bar would show for that session.
3. Check the link map under the `sessions` key in `~/.local/share/nvim/doit/session.json` and the list files in `~/.local/share/nvim/doit/lists/`.
4. Check `which jq`.

The character limit is `CHAR_LIMIT` in Do-It.nvim's `tmux/scripts/todo-exec.sh`.
