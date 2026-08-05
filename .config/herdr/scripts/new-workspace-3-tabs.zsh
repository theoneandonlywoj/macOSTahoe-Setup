#!/bin/zsh
set -euo pipefail

# Optional override file. Define HERDR_3TAB_* variables here for personal defaults.
config_file="${HERDR_3TAB_CONFIG:-$HOME/.config/herdr/three-tab-workspace.env}"
if [[ -f "$config_file" ]]; then
  source "$config_file"
fi

cwd="${HERDR_3TAB_CWD:-${HERDR_ACTIVE_PANE_CWD:-$PWD}}"
workspace_label="${HERDR_3TAB_WORKSPACE_LABEL:-$(basename "$cwd")}"
source_workspace="${HERDR_ACTIVE_WORKSPACE_ID:-none}"

tab1_label="${HERDR_3TAB_TAB1_LABEL:-agent}"
tab2_label="${HERDR_3TAB_TAB2_LABEL:-git}"
tab3_label="${HERDR_3TAB_TAB3_LABEL:-status}"

git_user="$(git -C "$cwd" config user.name 2>/dev/null || true)"
if [[ -z "$git_user" ]]; then
  git_user="$(git config --global user.name 2>/dev/null || true)"
fi
if [[ -z "$git_user" ]]; then
  git_user="${USER:-there}"
fi

branch="$(git -C "$cwd" branch --show-current 2>/dev/null || true)"
if [[ -z "$branch" ]]; then
  branch="$(git -C "$cwd" rev-parse --short HEAD 2>/dev/null || true)"
fi
if [[ -z "$branch" ]]; then
  branch="none"
fi

agent_cmd='if command -v opencode >/dev/null 2>&1; then opencode; elif command -v claude >/dev/null 2>&1; then claude; else echo "No agent CLI found: install opencode or claude."; fi'
git_cmd='if command -v lazygit >/dev/null 2>&1; then lazygit; else echo "lazygit not found. Install it with: brew install lazygit"; fi'

cmd1="${HERDR_3TAB_CMD1:-$agent_cmd}"
cmd2="${HERDR_3TAB_CMD2:-$git_cmd}"
status_script="${HERDR_3TAB_STATUS_SCRIPT:-$HOME/.config/herdr/scripts/workspace-status.zsh}"

json_get() {
  python3 -c '
import json
import sys

data = json.load(sys.stdin)
value = data
for part in sys.argv[1].split("."):
    value = value[part]
print(value)
' "$1"
}

shell_quote() {
  python3 -c 'import shlex, sys; print(shlex.quote(sys.argv[1]))' "$1"
}

herdr notification show "Hello, $git_user!" --body "Creating $workspace_label workspace" >/dev/null 2>&1 || true

workspace_json=$(herdr workspace create --cwd "$cwd" --label "$workspace_label" --focus)
workspace_id=$(json_get "result.workspace.workspace_id" <<< "$workspace_json")
tab1_id=$(json_get "result.tab.tab_id" <<< "$workspace_json")
pane1_id=$(json_get "result.root_pane.pane_id" <<< "$workspace_json")

herdr tab rename "$tab1_id" "$tab1_label" >/dev/null

tab2_json=$(herdr tab create --workspace "$workspace_id" --cwd "$cwd" --label "$tab2_label" --no-focus)
pane2_id=$(json_get "result.root_pane.pane_id" <<< "$tab2_json")

tab3_json=$(herdr tab create --workspace "$workspace_id" --cwd "$cwd" --label "$tab3_label" --no-focus)
pane3_id=$(json_get "result.root_pane.pane_id" <<< "$tab3_json")

q_git_user=$(shell_quote "$git_user")
q_cwd=$(shell_quote "$cwd")
q_branch=$(shell_quote "$branch")
q_workspace_label=$(shell_quote "$workspace_label")
q_workspace_id=$(shell_quote "$workspace_id")
q_source_workspace=$(shell_quote "$source_workspace")
q_status_script=$(shell_quote "$status_script")

status_cmd="clear; HERDR_STATUS_GIT_USER=$q_git_user HERDR_STATUS_CWD=$q_cwd HERDR_STATUS_BRANCH=$q_branch HERDR_STATUS_WORKSPACE_LABEL=$q_workspace_label HERDR_STATUS_WORKSPACE_ID=$q_workspace_id HERDR_STATUS_SOURCE_WORKSPACE=$q_source_workspace $q_status_script"
cmd3="${HERDR_3TAB_CMD3:-$status_cmd}"

herdr pane run "$pane1_id" "$cmd1" >/dev/null
herdr pane run "$pane2_id" "$cmd2" >/dev/null
herdr pane run "$pane3_id" "$cmd3" >/dev/null

herdr workspace focus "$workspace_id" >/dev/null
