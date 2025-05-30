#!/bin/bash

# Script to list all meetings from now until midnight
# Can be called as a tmux command

# Get exclude patterns from tmux config, fallback to environment variable
TMUX_EXCLUDE_PATTERNS=$(tmux show-option -gqv @bearded_giant_meetings_exclude 2>/dev/null || echo "")
if [[ -n "$TMUX_EXCLUDE_PATTERNS" ]]; then
    IFS=',' read -ra EXCLUDE_PATTERNS <<< "$TMUX_EXCLUDE_PATTERNS"
elif [[ -n "$BG_EXCLUDE_PATTERNS" ]]; then
    IFS=',' read -ra EXCLUDE_PATTERNS <<< "$BG_EXCLUDE_PATTERNS"
else
    EXCLUDE_PATTERNS=()
fi

# Get all meetings for today
meetings=$(icalBuddy \
    --includeEventProps "title,datetime" \
    --propertyOrder "datetime,title" \
    --noCalendarNames \
    --dateFormat "%I:%M %p" \
    --includeOnlyEventsFromNowOn \
    --excludeAllDayEvents \
    --separateByDate \
    --bullet "  •" \
    eventsToday)

# Process and filter meetings
echo "📅 Meetings for the rest of today:"
echo "================================="

time_range=""
meeting_count=0

while IFS= read -r line; do
    [[ "$line" == "today:" ]] && continue
    [[ "$line" == "------------------------" ]] && continue
    
    if [[ -z "$time_range" ]]; then
        # This should be a time range line (not indented)
        if [[ "$line" =~ ^[[:space:]] ]]; then
            continue
        fi
        time_range="$line"
    else
        # This should be a title line (indented)
        title=$(echo "$line" | sed 's/^[[:space:]]*•[[:space:]]*//')
        
        # Check if meeting should be excluded
        skip=false
        for pattern in "${EXCLUDE_PATTERNS[@]}"; do
            pattern_lower=$(echo "$pattern" | tr '[:upper:]' '[:lower:]')
            title_lower=$(echo "$title" | tr '[:upper:]' '[:lower:]')
            if [[ "$title_lower" == "$pattern_lower" ]] || [[ "$title_lower" == *"$pattern_lower"* ]]; then
                skip=true
                break
            fi
        done
        
        if ! $skip; then
            # Get minutes to meeting
            start_time=$(echo "$time_range" | awk -F ' - ' '{print $1}' | sed 's/[[:space:]]/ /g' | xargs)
            today_date=$(date +"%Y-%m-%d")
            datetime_str="$today_date $start_time"
            epoc_meeting=$(date -j -f "%Y-%m-%d %l:%M %p" "$datetime_str" +%s 2>/dev/null)
            epoc_now=$(date +%s)
            
            if [[ -n "$epoc_meeting" ]]; then
                epoc_diff=$((epoc_meeting - epoc_now))
                minutes_till=$((epoc_diff / 60))
                
                # Color coding based on time
                if ((minutes_till < -30)); then
                    # Meeting started more than 30 minutes ago, likely in progress
                    color="\033[35m"  # Magenta
                    time_info="(IN PROGRESS)"
                elif ((minutes_till < 0)); then
                    color="\033[31m"  # Red
                    time_info="(STARTED)"
                elif ((minutes_till < 15)); then
                    color="\033[31m"  # Red
                    time_info="(in ${minutes_till} min)"
                elif ((minutes_till < 30)); then
                    color="\033[33m"  # Yellow
                    time_info="(in ${minutes_till} min)"
                elif ((minutes_till < 60)); then
                    color="\033[34m"  # Blue
                    time_info="(in ${minutes_till} min)"
                else
                    hours=$((minutes_till / 60))
                    mins=$((minutes_till % 60))
                    color="\033[34m"  # Blue
                    if ((mins > 0)); then
                        time_info="(in ${hours}h ${mins}m)"
                    else
                        time_info="(in ${hours}h)"
                    fi
                fi
                
                # Format and display
                printf "${color}%-20s %-40s %s\033[0m\n" "$time_range" "$title" "$time_info"
                ((meeting_count++))
            fi
        fi
        
        time_range=""
    fi
done <<<"$meetings"

if ((meeting_count == 0)); then
    echo "🎉 No meetings for the rest of today!"
fi

echo "================================="
echo "Total meetings: $meeting_count"