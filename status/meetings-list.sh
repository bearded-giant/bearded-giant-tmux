#!/bin/bash

# Full-day agenda popup. Bound to prefix + M via display-popup.
# Shows every event (past dimmed, in-progress green, upcoming color-coded),
# overlapping meetings each on their own line. No exclude filtering here on
# purpose -- the status bar honors @bearded_giant_meetings_exclude, the popup
# shows the whole day like MeetingBar.

DIM="\033[90m"
RED="\033[31m"
YELLOW="\033[33m"
BLUE="\033[34m"
GREEN="\033[1;32m"
BOLD="\033[1m"
RESET="\033[0m"

today_date=$(date +"%Y-%m-%d")
epoc_now=$(date +%s)

to_epoch() {
  local t
  t=$(echo "$1" | sed 's/[[:space:]]/ /g' | xargs)
  [[ -z "$t" ]] && return
  date -j -f "%Y-%m-%d %l:%M %p" "$today_date $t" +%s 2>/dev/null
}

meetings=$(icalBuddy \
    --includeEventProps "title,datetime" \
    --propertyOrder "datetime,title" \
    --noCalendarNames \
    --dateFormat "%I:%M %p" \
    --excludeAllDayEvents \
    --separateByDate \
    --bullet "" \
    eventsToday)

render() {
  printf "  ${BOLD}%s${RESET}   ${DIM}now %s${RESET}\n" \
    "$(date +"Today · %a %b %d")" "$(date +"%-I:%M %p")"
  printf "  ${DIM}──────────────────────────────────────────────────────────────${RESET}\n"

  local time_range="" count=0 next_shown=0
  while IFS= read -r line; do
    [[ "$line" == "today:" || "$line" == "------------------------" ]] && continue

    if [[ -z "$time_range" ]]; then
      [[ "$line" =~ ^[[:space:]] ]] && continue
      time_range="$line"
      continue
    fi

    local title start end start_e end_e color tag mark
    title=$(echo "$line" | sed 's/^[[:space:]]*//' | xargs)
    start=$(echo "$time_range" | awk -F ' - ' '{print $1}' | sed 's/[[:space:]]/ /g' | xargs)
    end=$(echo "$time_range" | awk -F ' - ' '{print $2}' | sed 's/[[:space:]]/ /g' | xargs)
    start_e=$(to_epoch "$start")
    end_e=$(to_epoch "$end")
    time_range=""
    [[ -z "$start_e" ]] && continue

    ((${#title} > 30)) && title="${title:0:29}…"
    mark=" "

    if [[ -n "$end_e" && $end_e -le $epoc_now ]]; then
      color="$DIM"; tag="done"
    elif [[ $start_e -le $epoc_now ]]; then
      color="$GREEN"; mark="●"; tag="now"
    else
      local mins=$(((start_e - epoc_now) / 60)) t
      if ((mins < 5)); then color="$RED"
      elif ((mins < 30)); then color="$YELLOW"
      else color="$BLUE"; fi
      if ((mins >= 60)); then
        local h=$((mins / 60)) m=$((mins % 60))
        ((m > 0)) && t="in ${h}h ${m}m" || t="in ${h}h"
      else t="in ${mins}m"; fi
      tag="$t"
      ((next_shown == 0)) && { mark="◆"; next_shown=1; }
    fi

    printf "  ${color}%s %-8s → %-8s  %-30s %s${RESET}\n" "$mark" "$start" "$end" "$title" "$tag"
    ((count++))
  done <<<"$meetings"

  printf "  ${DIM}──────────────────────────────────────────────────────────────${RESET}\n"
  if ((count == 0)); then
    printf "  ${DIM}No events today 🎉${RESET}\n"
  else
    printf "  ${DIM}%d events · ◆ next up · q / Esc to close${RESET}\n" "$count"
  fi
}

if [[ -t 1 ]]; then
  # ponytail: no scroll -- days fit the popup; add a pager if they stop fitting
  render
  while IFS= read -rsn1 key; do
    [[ "$key" == "q" || "$key" == $'\e' ]] && break
  done
else
  render
fi
