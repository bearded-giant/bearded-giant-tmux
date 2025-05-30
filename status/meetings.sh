#!/bin/bash

ALERT_IF_IN_NEXT_MINUTES=90
MAX_HOURS_TO_SHOW=4  # Don't show "next in" if meeting is more than 4 hours away
NERD_FONT_FREE=""
NERD_FONT_MEETING=""

FREE_TIME_MESSAGE="$NERD_FONT_FREE  Free  "

# Get exclude patterns from tmux config, fallback to environment variable
TMUX_EXCLUDE_PATTERNS=$(tmux show-option -gqv @bearded_giant_meetings_exclude 2>/dev/null || echo "")
if [[ -n "$TMUX_EXCLUDE_PATTERNS" ]]; then
    IFS=',' read -ra EXCLUDE_PATTERNS <<< "$TMUX_EXCLUDE_PATTERNS"
elif [[ -n "$BG_EXCLUDE_PATTERNS" ]]; then
    IFS=',' read -ra EXCLUDE_PATTERNS <<< "$BG_EXCLUDE_PATTERNS"
else
    EXCLUDE_PATTERNS=()
fi

get_all_meetings() {
    icalBuddy \
        --includeEventProps "title,datetime" \
        --propertyOrder "datetime,title" \
        --noCalendarNames \
        --dateFormat "%I:%M %p" \
        --includeOnlyEventsFromNowOn \
        --excludeAllDayEvents \
        --separateByDate \
        --bullet "" \
        --excludeCals "" \
        eventsToday
}

get_minutes_to_meeting() {
    local time_range="$1"
    local time=$(echo "$time_range" | awk -F ' - ' '{print $1}' | sed 's/[[:space:]]/ /g' | xargs)
    local today_date=$(date +"%Y-%m-%d")
    local datetime_str="$today_date $time"
    local epoc_meeting=$(date -j -f "%Y-%m-%d %l:%M %p" "$datetime_str" +%s 2>/dev/null)
    local epoc_now=$(date +%s)
    
    if [[ -z "$epoc_meeting" ]]; then
        return
    fi
    
    local epoc_diff=$((epoc_meeting - epoc_now))
    local minutes_till_meeting=$((epoc_diff / 60))
    
    if ((minutes_till_meeting > 0)); then
        echo "$minutes_till_meeting"
    fi
}

get_meeting_status() {
    meetings=$(get_all_meetings)

    # Parse meetings - format is: time_range on one line, then title (indented) on next line
    time_range=""
    local upcoming_meetings=()
    local meeting_times=()
    local first_meeting=""
    local first_meeting_start=""
    local first_meeting_end=""
    local first_meeting_start_epoch=""
    local first_meeting_end_epoch=""
    local overlapping_count=0
    local next_meeting_minutes=""

    while IFS= read -r line; do
        [[ "$line" == "today:" || "$line" == "------------------------" ]] && continue

        if [[ -z "$time_range" ]]; then
            # This should be a time range line (not indented)
            if [[ "$line" =~ ^[[:space:]] ]]; then
                continue # Skip if this line starts with whitespace (shouldn't happen for time)
            fi
            time_range="$line"
        else
            # This should be a title line (indented)
            title=$(echo "$line" | sed 's/^[[:space:]]*//') # Remove leading whitespace

            # Process this meeting
            result=$(process_meeting "$time_range" "$title")
            
            # Always check for next meeting time for "Free" status
            if [[ -z "$next_meeting_minutes" ]]; then
                local temp_minutes=$(get_minutes_to_meeting "$time_range")
                if [[ -n "$temp_minutes" ]]; then
                    next_meeting_minutes="$temp_minutes"
                fi
            fi
            
            if [[ -n "$result" ]]; then
                upcoming_meetings+=("$result")
                meeting_times+=("$time_range")
                
                if [[ -z "$first_meeting" ]]; then
                    first_meeting="$result"
                    first_meeting_start=$(echo "$time_range" | awk -F ' - ' '{print $1}' | sed 's/[[:space:]]/ /g' | xargs)
                    first_meeting_end=$(echo "$time_range" | awk -F ' - ' '{print $2}' | sed 's/[[:space:]]/ /g' | xargs)
                    
                    # Convert to epoch for overlap checking
                    today_date=$(date +"%Y-%m-%d")
                    first_meeting_start_epoch=$(date -j -f "%Y-%m-%d %l:%M %p" "$today_date $first_meeting_start" +%s 2>/dev/null)
                    first_meeting_end_epoch=$(date -j -f "%Y-%m-%d %l:%M %p" "$today_date $first_meeting_end" +%s 2>/dev/null)
                else
                    # Check if this meeting overlaps with the first one
                    current_start=$(echo "$time_range" | awk -F ' - ' '{print $1}' | sed 's/[[:space:]]/ /g' | xargs)
                    current_end=$(echo "$time_range" | awk -F ' - ' '{print $2}' | sed 's/[[:space:]]/ /g' | xargs)
                    
                    # Convert to epoch for comparison
                    current_start_epoch=$(date -j -f "%Y-%m-%d %l:%M %p" "$today_date $current_start" +%s 2>/dev/null)
                    current_end_epoch=$(date -j -f "%Y-%m-%d %l:%M %p" "$today_date $current_end" +%s 2>/dev/null)
                    
                    # Check for actual overlap: start1 < end2 AND start2 < end1
                    if [[ -n "$current_start_epoch" && -n "$current_end_epoch" && 
                          -n "$first_meeting_start_epoch" && -n "$first_meeting_end_epoch" ]]; then
                        if [[ $first_meeting_start_epoch -lt $current_end_epoch && 
                              $current_start_epoch -lt $first_meeting_end_epoch ]]; then
                            overlapping_count=$((overlapping_count + 1))
                        fi
                    fi
                fi
            fi

            # Reset for next meeting
            time_range=""
        fi
    done <<<"$meetings"

    # Check if we have any upcoming meetings
    if [[ ${#upcoming_meetings[@]} -eq 0 ]]; then
        local max_minutes=$((MAX_HOURS_TO_SHOW * 60))
        if [[ -n "$next_meeting_minutes" ]] && ((next_meeting_minutes <= max_minutes)); then
            if ((next_meeting_minutes >= 60)); then
                local hours=$((next_meeting_minutes / 60))
                local mins=$((next_meeting_minutes % 60))
                if ((mins > 0)); then
                    echo "blue|$NERD_FONT_FREE  Free - next in ${hours}h ${mins}m  "
                else
                    echo "blue|$NERD_FONT_FREE  Free - next in ${hours}h  "
                fi
            else
                echo "blue|$NERD_FONT_FREE  Free - next in ${next_meeting_minutes} min  "
            fi
        else
            echo "blue|$FREE_TIME_MESSAGE"
        fi
    elif [[ ${#upcoming_meetings[@]} -eq 1 ]]; then
        echo "$first_meeting"
    else
        # Multiple meetings - show count
        meeting_color=$(echo "$first_meeting" | cut -d'|' -f1)
        meeting_text=$(echo "$first_meeting" | cut -d'|' -f2-)
        
        if [[ $overlapping_count -gt 0 ]]; then
            echo "${meeting_color}|${meeting_text} (+${overlapping_count} overlap)"
        else
            # Show total count of additional meetings
            echo "${meeting_color}|${meeting_text} (+$((${#upcoming_meetings[@]} - 1)) more)"
        fi
    fi
}

process_meeting() {
    local time_range="$1"
    local title="$2"

    skip=false
    for pattern in "${EXCLUDE_PATTERNS[@]}"; do
        # Support both exact match and wildcard patterns (case-insensitive)
        pattern_lower=$(echo "$pattern" | tr '[:upper:]' '[:lower:]')
        title_lower=$(echo "$title" | tr '[:upper:]' '[:lower:]')
        if [[ "$title_lower" == "$pattern_lower" ]] || [[ "$title_lower" == *"$pattern_lower"* ]]; then
            skip=true
            break
        fi
    done
    $skip && return

    time=$(echo "$time_range" | awk -F ' - ' '{print $1}')
    # end_time=$(echo "$time_range" | awk -F ' - ' '{print $2}')

    # Clean the time string - remove non-breaking spaces and other unicode characters
    time=$(echo "$time" | sed 's/[[:space:]]/ /g' | xargs)

    # Get today's date and combine with time for parsing
    today_date=$(date +"%Y-%m-%d")
    datetime_str="$today_date $time"
    epoc_meeting=$(date -j -f "%Y-%m-%d %l:%M %p" "$datetime_str" +%s 2>/dev/null)
    epoc_now=$(date +%s)

    if [[ -z "$epoc_meeting" ]]; then
        return
    fi

    epoc_diff=$((epoc_meeting - epoc_now))
    minutes_till_meeting=$((epoc_diff / 60))
    
    # Include meetings that started up to 5 minutes ago
    if ((epoc_diff < -300)); then  # More than 5 minutes past start
        return
    fi

    local max_minutes=$((MAX_HOURS_TO_SHOW * 60))
    if ((minutes_till_meeting > max_minutes)); then
        return
    fi

    title=$(echo "$title" | xargs)
    time=$(echo "$time" | xargs)

    char_limit=20
    if [[ ${#title} -gt $char_limit ]]; then
        title="${title:0:$char_limit}..."
    fi

    # Default
    status_color="blue"

    if ((minutes_till_meeting < -5)); then
        # Should not reach here due to earlier filter, but just in case
        return
    elif ((minutes_till_meeting < 0)); then
        # Meeting started within last 5 minutes
        minutes_late=$(( -minutes_till_meeting ))
        output="$NERD_FONT_MEETING STARTED ${minutes_late}m ago: $title"
        status_color="red"
    elif ((minutes_till_meeting >= 90)); then
        hours=$((minutes_till_meeting / 60))
        mins=$((minutes_till_meeting % 60))
        if ((mins > 0)); then
            output="$NERD_FONT_MEETING ${hours}h ${mins}m - $title"
        else
            output="$NERD_FONT_MEETING ${hours}h - $title"
        fi
        status_color="blue"
    elif ((minutes_till_meeting >= 60)); then
        output="$NERD_FONT_MEETING ${minutes_till_meeting} min - $title"
        status_color="blue"
    elif ((minutes_till_meeting >= 30)); then
        output="$NERD_FONT_MEETING $minutes_till_meeting min - $title"
        status_color="blue"
    elif ((minutes_till_meeting > 15)); then
        output="$NERD_FONT_MEETING In $minutes_till_meeting min - $title"
        status_color="yellow"
    elif ((minutes_till_meeting > 5)); then
        output="$NERD_FONT_MEETING In $minutes_till_meeting min - $title"
        status_color="orange"
    elif ((minutes_till_meeting > 2)); then
        output="$NERD_FONT_MEETING In $minutes_till_meeting min - $title"
        status_color="red"
    else
        output="$NERD_FONT_MEETING $title in $minutes_till_meeting minutes"
        status_color="red"
    fi

    echo "${status_color}|${output}"
}

format_meeting_output() {
    local index=$1
    local result=$2
    local icon
    local color
    local text
    local module

    meeting_color=$(echo "$result" | cut -d'|' -f1)
    meeting_text=$(echo "$result" | cut -d'|' -f2-)

    meeting_text_trimmed=$(echo "$meeting_text" | xargs)

    # if [[ "${meeting_text_trimmed,,}" == *"free"* ]]; then
    if [[ "$meeting_text_trimmed" == *"Free"* ]]; then
        # icon="☕"
        icon="👍"
    else
        icon="📅"
    fi

    case "$meeting_color" in
    "blue") color="$thm_blue" ;;
    "yellow") color="$thm_yellow" ;;
    "orange") color="$thm_orange" ;;
    "red") color="$thm_red" ;;
    "purple") color="$thm_purple" ;;
    *) color="$thm_blue" ;; # fallback
    esac

    text="  $meeting_text_trimmed  "

    module=$(build_status_module "$index" "$icon" "$color" "$text")

    echo "$module"
}

show_meetings() {
    local index=$1
    local icon
    local color
    local text
    local module
    
    # Get the current meeting status to determine color
    local result=$(get_meeting_status)
    local meeting_color=$(echo "$result" | cut -d'|' -f1)
    local meeting_text=$(echo "$result" | cut -d'|' -f2-)
    local meeting_text_trimmed=$(echo "$meeting_text" | xargs)
    
    # Set icon based on content
    if [[ "$meeting_text_trimmed" == *"Free"* ]]; then
        icon="👍"
    else
        icon="📅"
    fi
    
    # Set color based on meeting status
    case "$meeting_color" in
    "blue") color="$thm_blue" ;;
    "yellow") color="$thm_yellow" ;;
    "orange") color="$thm_orange" ;;
    "red") color="$thm_red" ;;
    "purple") color="$thm_purple" ;;
    *) color="$thm_blue" ;; # fallback
    esac
    
    # Create a command that tmux will execute dynamically for the text
    local script_path="${PLUGIN_DIR}/status/meetings-exec.sh"
    text="  #(${script_path})  "
    
    # Build the module with dynamic text
    module=$(build_status_module "$index" "$icon" "$color" "$text")
    
    echo "$module"
}

# If script is run directly (not sourced), output the meeting status
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Get the plugin directory
    PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    
    # Source the theme file for colors
    source "${PLUGIN_DIR}/bearded-giant-dark.tmuxtheme"
    
    # Source the build_status_module function from main script
    source "${PLUGIN_DIR}/bearded-giant.tmux"
    
    if [[ "$1" == "format" && -n "$2" ]]; then
        # Called from tmux to format the output
        result=$(get_meeting_status)
        format_meeting_output "$2" "$result"
    else
        # Called directly for testing
        get_meeting_status
    fi
fi
