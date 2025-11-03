# Todo Integration for Bearded Giant Tmux Theme

This adds support for displaying the current in-progress todo from BeardedGiant's Do-It.nvim framework in your tmux status bar.

## Dependencies

**IMPORTANT**: This integration requires [Do-It.nvim](https://github.com/bearded-giant/do-it.nvim) to be installed and configured in Neovim. Do-It.nvim is a modular task management framework for Neovim that provides:
- Multiple todo lists management
- Task prioritization and organization
- Persistent storage of todos in JSON format
- In-progress task tracking
- Project-specific notes and documentation
- Calendar integration with due dates

Without Do-It.nvim installed and a `daily` list created, this tmux integration will not display any todos.

## Features

- Shows the current in-progress todo from your Do-It.nvim `daily` list
- Falls back to the next undone todo if no in-progress item
- Shows "All done!" when all todos are completed
- Color-coded status (green for in-progress, yellow for pending, blue for completed)
- Automatically truncates long todo text to fit in status bar

## Setup

### Prerequisites

1. Install and configure [Do-It.nvim](https://github.com/bearded-giant/do-it.nvim) in your Neovim setup:
   ```lua
   -- Using Lazy.nvim
   return {
       "bearded-giant/do-it.nvim",
       config = function()
           require("doit").setup()
       end,
   }
   ```
2. Create a `daily` todo list in Do-It.nvim (or ensure it exists):
   - Open todos with `:Doit` or `<leader>td`
   - Create or switch to the `daily` list using the list management commands
3. Ensure you have `jq` installed:
   ```bash
   brew install jq  # macOS
   apt-get install jq  # Ubuntu/Debian
   ```

### Configuration

1. The todo module is already installed in `status/todo.sh`

2. Add the todo module to your tmux configuration:
   ```bash
   # In your .tmux.conf or where you configure bearded-giant
   set -g @bearded_giant_status_modules_right "meetings todo"
   ```

4. Reload tmux configuration:
   ```bash
   tmux source-file ~/.tmux.conf
   ```

## How it Works

The todo module reads from `~/.local/share/nvim/doit/lists/daily.json`, which is where Do-It.nvim stores the daily todo list.

It prioritizes todos in this order:
1. First in-progress todo (marked with `in_progress: true`)
2. First pending todo (marked with `done: false`, sorted by order_index)
3. "All done!" message when no pending todos exist

## Files

- `status/todo.sh` - Main todo module that integrates with the theme
- `status/todo-exec.sh` - Executable script that fetches the current todo text
- Both scripts use `jq` to parse the JSON todo list

## Customization

You can adjust the character limit for todo display by editing `CHAR_LIMIT` in the scripts (default is 25 characters).

## Troubleshooting

If todos aren't showing:
1. Verify Do-It.nvim is installed and working in Neovim
2. Check that `~/.local/share/nvim/doit/lists/daily.json` exists
3. Ensure `jq` is installed: `which jq`
4. Test the script directly: `/Users/bryan/dev/tmux/bearded-giant-tmux/status/todo-exec.sh`
5. Make sure you've added "todo" to your status modules configuration
6. Confirm you have todos in your `daily` list by opening Do-It.nvim (`:Doit`)

## About Do-It.nvim

Do-It.nvim is a modular task management framework created by BeardedGiant, originally forked from Dooing by atiladefreitas. It provides a clean, distraction-free interface to manage tasks and notes directly within Neovim, perfect for developers who want to track their work without leaving their editor.