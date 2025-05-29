# Meeting Exclude Patterns

The meeting status module supports excluding certain meetings from display using the `BG_EXCLUDE_PATTERNS` environment variable.

## Usage

Set the `BG_EXCLUDE_PATTERNS` environment variable in your tmux config:

```bash
# Single pattern
set-environment -g BG_EXCLUDE_PATTERNS "Standup"

# Multiple patterns (comma-separated)
set-environment -g BG_EXCLUDE_PATTERNS "Standup,Stand-up,AFK,Lunch"
```

## Features

- **Case-insensitive matching**: Patterns are matched case-insensitively
- **Partial matching**: Pattern "standup" will match "ME Team Standup", "Standup Meeting", etc.
- **Multiple patterns**: Separate multiple patterns with commas

## Examples

```bash
# Exclude all standup meetings (matches "Standup", "Stand-up", "Daily Standup", etc.)
set-environment -g BG_EXCLUDE_PATTERNS "standup,stand-up"

# Exclude personal time blocks
set-environment -g BG_EXCLUDE_PATTERNS "AFK,Lunch,Break,Personal"

# Exclude recurring meetings
set-environment -g BG_EXCLUDE_PATTERNS "Weekly Sync,1:1,Status Update"
```

## How it works

1. The script converts the comma-separated string into an array
2. For each meeting, it checks if any exclude pattern matches
3. Matching is case-insensitive and supports partial matches
4. Excluded meetings are completely hidden from the status display