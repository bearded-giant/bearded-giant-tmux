#!/bin/bash

NERD_FONT_FREE=""
NERD_FONT_MEETING=""

FREE_TIME_MESSAGE="$NERD_FONT_FREE Free"

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

get_meeting_status() {
    local meetings time_range="" title result
    meetings=$(get_all_meetings)
    while IFS= read -r line; do
        [[ "$line" == "today:" || "$line" == "------------------------" ]] && continue
        if [[ -z "$time_range" ]]; then
            [[ "$line" =~ ^[[:space:]] ]] && continue
            time_range="$line"
        else
            title=$(echo "$line" | sed 's/^[[:space:]]*//')
            result=$(process_meeting "$time_range" "$title")
            time_range=""
            if [[ -n "$result" ]]; then
                echo "$result"
                return
            fi
        fi
    done <<<"$meetings"
    echo "blue|$FREE_TIME_MESSAGE"
}

process_meeting() {
    local time_range="$1"
    local title="$2"

    skip=false
    for pattern in "${EXCLUDE_PATTERNS[@]}"; do
        pattern_lower=$(echo "$pattern" | tr '[:upper:]' '[:lower:]')
        title_lower=$(echo "$title" | tr '[:upper:]' '[:lower:]')
        if [[ "$title_lower" == "$pattern_lower" ]] || [[ "$title_lower" == *"$pattern_lower"* ]]; then
            skip=true
            break
        fi
    done
    $skip && return

    time=$(echo "$time_range" | awk -F ' - ' '{print $1}')
    time=$(echo "$time" | sed 's/[[:space:]]/ /g' | xargs)

    today_date=$(date +"%Y-%m-%d")
    datetime_str="$today_date $time"
    epoc_meeting=$(date -j -f "%Y-%m-%d %l:%M %p" "$datetime_str" +%s 2>/dev/null)
    epoc_now=$(date +%s)

    if [[ -z "$epoc_meeting" ]]; then
        return
    fi

    epoc_diff=$((epoc_meeting - epoc_now))
    minutes_till_meeting=$((epoc_diff / 60))

    # skip meetings that started more than 5 minutes ago
    if ((epoc_diff < -300)); then
        return
    fi

    title=$(echo "$title" | xargs)

    char_limit=16
    if [[ ${#title} -gt $char_limit ]]; then
        title="${title:0:$char_limit}..."
    fi

    status_color="blue"
    if ((minutes_till_meeting < 0)); then
        output="NOW $title"; status_color="red"
    elif ((minutes_till_meeting >= 60)); then
        hours=$((minutes_till_meeting / 60))
        mins=$((minutes_till_meeting % 60))
        ((mins > 0)) && output="${hours}h${mins}m $title" || output="${hours}h $title"
    elif ((minutes_till_meeting > 15)); then
        output="${minutes_till_meeting}m $title"; status_color="yellow"
    elif ((minutes_till_meeting > 5)); then
        output="${minutes_till_meeting}m $title"; status_color="orange"
    else
        output="${minutes_till_meeting}m $title"; status_color="red"
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

    if [[ "$meeting_text_trimmed" == *"Free"* ]]; then
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
    *) color="$thm_blue" ;;
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

    local result=$(get_meeting_status)
    local meeting_color=$(echo "$result" | cut -d'|' -f1)
    local meeting_text=$(echo "$result" | cut -d'|' -f2-)
    local meeting_text_trimmed=$(echo "$meeting_text" | xargs)

    if [[ "$meeting_text_trimmed" == *"Free"* ]]; then
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
    *) color="$thm_blue" ;;
    esac

    local script_path="${PLUGIN_DIR}/status/meetings-exec.sh"
    text=" #(${script_path}) "
    module=$(build_status_module "$index" "$icon" "$color" "$text")
    echo "$module"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    source "${PLUGIN_DIR}/bearded-giant-dark.tmuxtheme"
    source "${PLUGIN_DIR}/bearded-giant.tmux"

    if [[ "$1" == "format" && -n "$2" ]]; then
        result=$(get_meeting_status)
        format_meeting_output "$2" "$result"
    else
        get_meeting_status
    fi
fi
