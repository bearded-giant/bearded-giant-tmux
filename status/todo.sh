#!/bin/bash

# Module for displaying current todo from do-it.nvim
# This file should be sourced by the main tmux theme script

TODO_LIST_PATH="$HOME/.local/share/nvim/doit/lists/daily.json"
CHAR_LIMIT=25

get_todo_status() {
    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        echo "gray|No jq"
        return
    fi

    # Check if the daily list file exists
    if [[ ! -f "$TODO_LIST_PATH" ]]; then
        echo "gray|No todos"
        return
    fi

    # Get the first in-progress todo
    local todo_text=$(jq -r '.todos[] | select(.in_progress == true) | .text' "$TODO_LIST_PATH" 2>/dev/null | head -1)
    local status_color="green"  # Default for in-progress

    # If no in-progress todo found, check for any undone todo
    if [[ -z "$todo_text" ]]; then
        # Get the first undone todo (sorted by order_index)
        todo_text=$(jq -r '.todos | sort_by(.order_index) | .[] | select(.done == false) | .text' "$TODO_LIST_PATH" 2>/dev/null | head -1)
        status_color="yellow"  # Different color for pending todos

        # If still nothing, show a completion message
        if [[ -z "$todo_text" ]]; then
            echo "blue|✓ All done!"
            return
        fi
    fi

    # Clean and truncate the text
    todo_text=$(echo "$todo_text" | xargs)  # Trim whitespace

    if [[ ${#todo_text} -gt $CHAR_LIMIT ]]; then
        todo_text="${todo_text:0:$CHAR_LIMIT}..."
    fi

    echo "${status_color}|${todo_text}"
}

show_todo() {
    local index=$1
    local icon
    local color
    local text
    local module

    # Get the current todo status to determine color
    local result=$(get_todo_status)
    local todo_color=$(echo "$result" | cut -d'|' -f1)
    local todo_text=$(echo "$result" | cut -d'|' -f2-)
    local todo_text_trimmed=$(echo "$todo_text" | xargs)

    # Set icon based on status
    if [[ "$todo_text_trimmed" == *"All done"* ]]; then
        icon="✅"
    else
        icon="📝"  # Task icon for active todos
    fi

    # Set color based on todo status
    case "$todo_color" in
    "green") color="$thm_green" ;;
    "yellow") color="$thm_yellow" ;;
    "blue") color="$thm_blue" ;;
    "gray") color="$thm_gray" ;;
    *) color="$thm_fg" ;; # fallback
    esac

    # Create a command that tmux will execute dynamically for the text
    local script_path="${PLUGIN_DIR}/status/todo-exec.sh"
    text="  #(${script_path})  "

    # Build the module with dynamic text
    module=$(build_status_module "$index" "$icon" "$color" "$text")

    echo "$module"
}

# If script is run directly (not sourced), output the todo status
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Get the plugin directory
    PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

    # Source the theme file for colors
    source "${PLUGIN_DIR}/bearded-giant-dark.tmuxtheme"

    # Source the build_status_module function from main script
    source "${PLUGIN_DIR}/bearded-giant.tmux"

    if [[ "$1" == "format" && -n "$2" ]]; then
        # Called from tmux to format the output
        result=$(get_todo_status)
        # Format output similar to meetings module
        todo_color=$(echo "$result" | cut -d'|' -f1)
        todo_text=$(echo "$result" | cut -d'|' -f2-)

        case "$todo_color" in
        "green") color="$thm_green" ;;
        "yellow") color="$thm_yellow" ;;
        "blue") color="$thm_blue" ;;
        "gray") color="$thm_gray" ;;
        *) color="$thm_fg" ;;
        esac

        icon="📝"
        if [[ "$todo_text" == *"All done"* ]]; then
            icon="✅"
        fi

        text="  $todo_text  "
        module=$(build_status_module "$2" "$icon" "$color" "$text")
        echo "$module"
    else
        # Called directly for testing
        get_todo_status
    fi
fi