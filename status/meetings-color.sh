#!/bin/bash

# This script outputs just the color for the current meeting status

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${PLUGIN_DIR}/status/meetings.sh"

# Get meeting status and extract color
result=$(get_meeting_status)
meeting_color=$(echo "$result" | cut -d'|' -f1)

# Map to tmux color codes
case "$meeting_color" in
    "red") echo "#e46876" ;;
    "orange") echo "#c4b28a" ;;
    "yellow") echo "#e6c384" ;;
    "blue") echo "#7fb4ca" ;;
    "purple") echo "#6b189d" ;;
    *) echo "#7fb4ca" ;; # default to blue
esac