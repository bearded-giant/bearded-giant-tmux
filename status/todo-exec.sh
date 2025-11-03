#!/bin/bash

# Get the current in-progress todo from do-it.nvim daily list
TODO_LIST_PATH="$HOME/.local/share/nvim/doit/lists/daily.json"
CHAR_LIMIT=25  # Character limit for todo text display
NERD_FONT_TASK=""  # Nerd font task icon
NERD_FONT_CHECK=""  # Alternative check icon
NERD_FONT_TARGET=""  # Alternative target icon

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo ""
    exit 0
fi

# Check if the daily list file exists
if [[ ! -f "$TODO_LIST_PATH" ]]; then
    echo ""
    exit 0
fi

# Get the first in-progress todo
todo_text=$(jq -r '.todos[] | select(.in_progress == true) | .text' "$TODO_LIST_PATH" 2>/dev/null | head -1)

# If no in-progress todo found, check for any undone todo
if [[ -z "$todo_text" ]]; then
    # Get the first undone todo (sorted by order_index)
    todo_text=$(jq -r '.todos | sort_by(.order_index) | .[] | select(.done == false) | .text' "$TODO_LIST_PATH" 2>/dev/null | head -1)

    # If still nothing, show a default message
    if [[ -z "$todo_text" ]]; then
        echo "$NERD_FONT_CHECK All done!"
        exit 0
    fi
fi

# Clean and truncate the text
todo_text=$(echo "$todo_text" | xargs)  # Trim whitespace

if [[ ${#todo_text} -gt $CHAR_LIMIT ]]; then
    todo_text="${todo_text:0:$CHAR_LIMIT}..."
fi

# Output with task icon
echo "$NERD_FONT_TASK $todo_text"