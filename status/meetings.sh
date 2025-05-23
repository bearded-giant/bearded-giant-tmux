#!/bin/bash

ALERT_IF_IN_NEXT_MINUTES=90
NERD_FONT_FREE=""
NERD_FONT_MEETING=""

FREE_TIME_MESSAGE="$NERD_FONT_FREE  Free  "

EXCLUDE_PATTERNS=$BG_EXCLUDE_PATTERNS

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

get_meeting_status() {
    meetings=$(get_all_meetings)

    # Parse meetings - format is: time_range on one line, then title (indented) on next line
    time_range=""
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
            if [[ -n "$result" ]]; then
                echo "$result"
                return
            fi

            # Reset for next meeting
            time_range=""
        fi
    done <<<"$meetings"

    # If we get here, no meetings were found in the time window
    echo "blue|$FREE_TIME_MESSAGE"
}

process_meeting() {
    local time_range="$1"
    local title="$2"

    skip=false
    for pattern in "${EXCLUDE_PATTERNS[@]}"; do
        if [[ "$title" == $pattern ]]; then
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

    if ((epoc_now >= epoc_meeting)); then
        return
    fi

    epoc_diff=$((epoc_meeting - epoc_now))
    minutes_till_meeting=$((epoc_diff / 60))

    if ((minutes_till_meeting > ALERT_IF_IN_NEXT_MINUTES)); then
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

    if ((minutes_till_meeting >= 60)); then
        hours=$((minutes_till_meeting / 60))
        mins=$((minutes_till_meeting % 60))
        output="$NERD_FONT_MEETING ${hours}h ${mins}m - $title"
        status_color="blue"
    elif ((minutes_till_meeting >= 30)); then
        output="$NERD_FONT_MEETING $minutes_till_meeting min - $title (soon)"
        status_color="yellow"
    elif ((minutes_till_meeting >= 5)); then
        output="$NERD_FONT_MEETING In $minutes_till_meeting min - $title"
        status_color="orange"
    else
        output="$NERD_FONT_MEETING Starting soon: $title"
        status_color="red"
    fi

    echo "${status_color}|${output}"
}

show_meetings() {
    local index=$1
    local icon
    local color
    local result
    local text
    local module

    result=$(get_meeting_status)

    meeting_color=$(echo "$result" | cut -d'|' -f1)
    meeting_text=$(echo "$result" | cut -d'|' -f2-)

    meeting_text_trimmed=$(echo "$meeting_text" | xargs)

    # if [[ "${meeting_text_trimmed,,}" == *"free"* ]]; then
    if [[ "$meeting_text_trimmed" == *"Free"* ]]; then
        # icon="☕"
        icon="👍"
    else
        # icon="📅"
        icon="👎"
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

# If script is run directly (not sourced), output the meeting status
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    get_meeting_status
fi

