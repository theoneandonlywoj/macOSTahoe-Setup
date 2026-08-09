#!/bin/zsh
set -euo pipefail

# Optional override file. Define HERDR_4TAB_* variables here for personal defaults.
# Reads ~/.config/herdr/scripts/.env when present, otherwise falls back to the
# checked-in template ~/.config/herdr/scripts/.env.example, otherwise inline defaults.
config_file="${HERDR_4TAB_CONFIG:-$HOME/.config/herdr/scripts/.env}"
if [[ ! -f "$config_file" ]]; then
  config_file="$HOME/.config/herdr/scripts/.env.example"
fi

# Read a HERDR_4TAB_* value: shell env > config file (grepped) > fallback.
env_value() {
  local key="$1"
  local fallback="$2"
  local shell_value file_value
  shell_value="${(P)key-}"
  file_value=$(grep -E "^${key}=" "$config_file" 2>/dev/null | head -1 | cut -d= -f2- | tr -d '"') || true
  if [[ -n "$shell_value" ]]; then
    print -r -- "$shell_value"
  elif [[ -n "$file_value" ]]; then
    print -r -- "$file_value"
  else
    print -r -- "$fallback"
  fi
}

cwd="$(env_value HERDR_4TAB_CWD "${HERDR_ACTIVE_PANE_CWD:-$PWD}")"
workspace_label="$(env_value HERDR_4TAB_WORKSPACE_LABEL "$(basename "$cwd")")"

tab1_label="$(env_value HERDR_4TAB_TAB1_LABEL agent-high)"
tab2_label="$(env_value HERDR_4TAB_TAB2_LABEL git)"
tab3_label="$(env_value HERDR_4TAB_TAB3_LABEL shell)"
tab4_label="$(env_value HERDR_4TAB_TAB4_LABEL agent-low)"

HARNESS_ORDER="$(env_value HERDR_4TAB_HARNESS_ORDER "claude codex opencode")"
CLAUDE_HIGH="$(env_value HERDR_4TAB_CLAUDE_HIGH "claude --permission-mode acceptEdits --model opus --effort max")"
CODEX_HIGH="$(env_value HERDR_4TAB_CODEX_HIGH "codex --approve-for-me -m gpt-5.6-sol -c model_reasoning_effort=high")"
OPENCODE_HIGH="$(env_value HERDR_4TAB_OPENCODE_HIGH "opencode --auto --variant high -m opencode-go/gpt-5.6-sol")"
CLAUDE_LOW="$(env_value HERDR_4TAB_CLAUDE_LOW "claude --permission-mode acceptEdits --model haiku")"
CODEX_LOW="$(env_value HERDR_4TAB_CODEX_LOW "codex --approve-for-me -m gpt-5.4-mini")"
OPENCODE_LOW="$(env_value HERDR_4TAB_OPENCODE_LOW "opencode --auto -m opencode/deepseek-v4-flash-free")"

# Pick the first harness in HARNESS_ORDER that has an installed binary, and print
# its command for the given mode (HIGH or LOW).
pick_harness_cmd() {
  local mode="$1"
  local harness varname
  for harness in ${=HARNESS_ORDER}; do
    if command -v "$harness" >/dev/null 2>&1; then
      varname="${(U)harness}_${mode}"
      if [[ -n "${(P)varname-}" ]]; then
        print -r -- "${(P)varname}"
        return 0
      fi
    fi
  done
  print -r -- "echo \"No agent CLI found: install one of: ${HARNESS_ORDER}\""
}

git_user="$(git -C "$cwd" config user.name 2>/dev/null || true)"
if [[ -z "$git_user" ]]; then
  git_user="$(git config --global user.name 2>/dev/null || true)"
fi
if [[ -z "$git_user" ]]; then
  git_user="${USER:-there}"
fi

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

agent_high_cmd="$(pick_harness_cmd HIGH)"
agent_low_cmd="$(pick_harness_cmd LOW)"

herdr notification show "Hello, $git_user!" --body "Creating $workspace_label workspace" >/dev/null 2>&1 || true

workspace_json=$(herdr workspace create --cwd "$cwd" --label "$workspace_label" --focus)
workspace_id=$(json_get "result.workspace.workspace_id" <<< "$workspace_json")
tab1_id=$(json_get "result.tab.tab_id" <<< "$workspace_json")
pane1_id=$(json_get "result.root_pane.pane_id" <<< "$workspace_json")

herdr tab rename "$tab1_id" "$tab1_label" >/dev/null

tab2_json=$(herdr tab create --workspace "$workspace_id" --cwd "$cwd" --label "$tab2_label" --no-focus)
tab3_json=$(herdr tab create --workspace "$workspace_id" --cwd "$cwd" --label "$tab3_label" --no-focus)
tab4_json=$(herdr tab create --workspace "$workspace_id" --cwd "$cwd" --label "$tab4_label" --no-focus)
pane4_id=$(json_get "result.root_pane.pane_id" <<< "$tab4_json")

herdr pane run "$pane1_id" "$agent_high_cmd" >/dev/null
# Tab 2 (git) and tab 3 (shell) stay as plain shells — no command is run.
herdr pane run "$pane4_id" "$agent_low_cmd" >/dev/null

herdr workspace focus "$workspace_id" >/dev/null
