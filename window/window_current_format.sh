show_window_current_format() {
  local number="$(get_tmux_option "@bearded_giant_window_current_number" "> #I <")"
  local color="$(get_tmux_option "@bearded_giant_window_current_color" "$thm_purple")"
  local background="$thm_bg"
  local text="$(get_tmux_option "@bearded_giant_window_current_text" "#{b:pane_current_path}")" # use #W for application instead of directory
  local fill="$(get_tmux_option "@bearded_giant_window_current_fill" "number")" # number, all, none

  local current_window_format=$( build_window_format "$number" "$color" "$background" "$text" "$fill" )

  echo "$current_window_format"
}
