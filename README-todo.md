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

### Display Features
- Shows the current in-progress todo from your Do-It.nvim `daily` list
- Falls back to the next undone todo if no in-progress item
- Shows "All done!" when all todos are completed
- Color-coded status (green for in-progress, yellow for pending, blue for completed)
- Automatically truncates long todo text to fit in status bar

### Interactive Features (NEW!)
- **Bidirectional sync** - Update todos from tmux that sync back to Do-It.nvim
- **Quick view popup** - See all your todos in a tmux popup window
- **Interactive manager** - Full todo management with fzf integration
- **Keyboard shortcuts** - Quick actions to toggle, start, and manage todos
- **Real-time updates** - Changes made in tmux immediately reflect in nvim

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
3. Ensure you have required dependencies installed:
   ```bash
   # Required for all features
   brew install jq  # macOS
   apt-get install jq  # Ubuntu/Debian

   # Optional for interactive manager
   brew install fzf  # macOS
   apt-get install fzf  # Ubuntu/Debian
   ```

### Configuration

1. The todo module is already installed in `status/todo.sh`

2. Add the todo module to your tmux configuration:
   ```bash
   # In your .tmux.conf or where you configure bearded-giant
   set -g @bearded_giant_status_modules_right "meetings todo"
   ```

4. Add keybindings for interactive todo management (optional):
   ```bash
   # Add to your .tmux.conf
   source-file ~/dev/tmux/bearded-giant-tmux/todo-keybindings.conf
   ```

   The keybindings use a two-key sequence to avoid conflicts:
   - **Prefix + d** then **t**: Show todo popup (quick view)
   - **Prefix + d** then **i**: Open interactive manager (requires fzf)
   - **Prefix + d** then **x**: Toggle current todo done/undone
   - **Prefix + d** then **n**: Start next pending todo

   Alternative direct keybindings (no prefix):
   - **Alt+Shift+T**: Show todo popup
   - **Alt+Shift+I**: Interactive manager
   - **Alt+Shift+X**: Toggle todo
   - **Alt+Shift+N**: Next todo

5. Reload tmux configuration:
   ```bash
   tmux source-file ~/.tmux.conf
   ```

## Usage

### Viewing Todos

Once configured, your current todo appears in the tmux status bar. To view all todos:

1. **Quick View** (Prefix + t): Shows a popup with todo statistics and lists
2. **Status Bar**: Always displays the current in-progress or next pending todo

### Managing Todos from Tmux

With keybindings configured, you can manage todos without leaving tmux:

#### Using Prefix + d menu (recommended):
1. **View Todos** (Prefix + d, then t): Show popup with todo statistics
2. **Toggle Done** (Prefix + d, then x): Mark current todo as done/undone
3. **Start Next** (Prefix + d, then n): Mark the next pending todo as in-progress
4. **Interactive Manager** (Prefix + d, then i): Full todo management with fzf

#### Using Alt+Shift shortcuts (alternative):
1. **Alt+Shift+T**: Quick todo view
2. **Alt+Shift+X**: Toggle current todo
3. **Alt+Shift+N**: Start next todo
4. **Alt+Shift+I**: Interactive manager

#### Interactive Manager Controls:
- Navigate with arrow keys
- Press Enter to toggle done status
- Press 's' to start a todo (mark as in-progress)
- Press 'x' to stop in-progress status
- Press 'q' or ESC to exit

### Syncing with Neovim

All changes made in tmux are immediately saved to the Do-It.nvim JSON file, so they're instantly available in Neovim:

1. Make changes in tmux (toggle, start, etc.)
2. Open Do-It.nvim in Neovim (`:Doit`)
3. Changes are already there!

Similarly, changes made in Neovim appear in tmux within 5 seconds (tmux status refresh interval).

## How it Works

The todo module reads from `~/.local/share/nvim/doit/lists/daily.json`, which is where Do-It.nvim stores the daily todo list.

It prioritizes todos in this order:
1. First in-progress todo (marked with `in_progress: true`)
2. First pending todo (marked with `done: false`, sorted by order_index)
3. "All done!" message when no pending todos exist

## Files

### Display Scripts
- `status/todo.sh` - Main todo module that integrates with the theme
- `status/todo-exec.sh` - Executable script that fetches the current todo text

### Interactive Scripts
- `status/todo-popup.sh` - Quick view popup showing todo statistics and lists
- `status/todo-interactive.sh` - Full interactive manager with fzf (create, edit, delete todos)
- `status/todo-toggle.sh` - Toggle the current todo between done/undone
- `status/todo-next.sh` - Mark the next pending todo as in-progress

### Configuration
- `todo-keybindings.conf` - Tmux keybinding configuration for todo management

All scripts use `jq` to parse and update the JSON todo list, ensuring full compatibility with Do-It.nvim.

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