#!/usr/bin/env bash
#
# clone-window.sh - clone current window layout and pane directories
#

set -euo pipefail

# get current window info
current_session=$(tmux display-message -p '#{session_name}')
current_window=$(tmux display-message -p '#{window_index}')
window_name=$(tmux display-message -p '#{window_name}')
layout=$(tmux display-message -p '#{window_layout}')

# get pane directories
mapfile -t pane_paths < <(tmux list-panes -t "${current_session}:${current_window}" -F '#{pane_current_path}')
pane_count=${#pane_paths[@]}

# create new window with first pane's directory
tmux new-window -c "${pane_paths[0]}" -n "${window_name}-clone"
new_window=$(tmux display-message -p '#{window_index}')

# create remaining panes (just need the right count, layout will fix positioning)
for ((i = 1; i < pane_count; i++)); do
    tmux split-window -t "${current_session}:${new_window}" -c "${pane_paths[$i]}"
done

# apply the original layout
tmux select-layout -t "${current_session}:${new_window}" "$layout"

# select first pane
tmux select-pane -t "${current_session}:${new_window}.0"
