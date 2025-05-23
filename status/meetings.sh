show_meetings() {
  local index=$1
  local icon
  local color
  local result
  local text
  local module

  result="$($HOME/.config/tmux/scripts/cal.sh)"

  meeting_color=$(echo "$result" | cut -d'|' -f1)
  meeting_text=$(echo "$result" | cut -d'|' -f2-)

  meeting_text_trimmed=$(echo "$meeting_text" | xargs)

  if [ "$meeting_text_trimmed" = "Freedom" ]; then
    icon="☕"
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