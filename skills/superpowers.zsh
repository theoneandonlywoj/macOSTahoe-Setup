#!/bin/zsh
# === superpowers.zsh ===
# Purpose: Install Superpowers skills (https://github.com/obra/superpowers) for Claude Code, Codex and OpenCode on macOS Tahoe
# Shell: Zsh (default)
# Author: theoneandonlywoj

echo "🚀 Starting Superpowers skills installation on macOS Tahoe..."
echo

# === 0. Configuration ===
SUPERPOWERS_REPO="https://github.com/obra/superpowers.git"
CLAUDE_SKILLS_DIR="$HOME/.claude/skills"
CODEX_SKILLS_DIR="$HOME/.codex/skills"
OPENCODE_INSTALL_URL="https://raw.githubusercontent.com/obra/superpowers/refs/heads/main/.opencode/INSTALL.md"

# === 1. Detect supported CLIs ===
echo "🔍 Detecting supported CLIs..."
typeset -a detected
for cli in claude codex opencode; do
  if command -v "$cli" >/dev/null 2>&1; then
    echo "✅ $cli detected: $(command -v "$cli")"
    detected+=("$cli")
  else
    echo "⚠️  $cli not found in PATH."
  fi
done

if [[ ${#detected[@]} -eq 0 ]]; then
  echo
  echo "❌ None of the supported CLIs (claude, codex, opencode) are installed."
  echo "   Install one first (e.g. run opencode.zsh for OpenCode) and re-run this script."
  exit 1
fi
echo

# === 2. Ask which CLI(s) to install for ===
echo "❓ Which CLI(s) do you want to install Superpowers for?"
i=1
for cli in "${detected[@]}"; do
  echo "   $i) $cli"
  ((i++))
done
echo "   a) all detected"

typeset -a selected
while true; do
  echo -n "👉 Enter your choice (e.g. '1', '1 2', or 'a'): "
  read choice
  if [[ "$choice" == [aA] ]]; then
    selected=("${detected[@]}")
    break
  fi
  selected=()
  valid=true
  for tok in ${(z)choice}; do
    if [[ "$tok" == <-> ]] && (( tok >= 1 && tok <= ${#detected[@]} )); then
      selected+=("${detected[$tok]}")
    else
      valid=false
      break
    fi
  done
  if [[ "$valid" == true && ${#selected[@]} -gt 0 ]]; then
    break
  fi
  echo "⚠️  Invalid choice. Please try again."
done
echo "📌 Installing Superpowers for: ${selected[*]}"
echo

# === 3. Clone the Superpowers repository (only needed for claude/codex) ===
TMP_DIR=""
SRC_DIR=""
if [[ " ${selected[*]} " == *" claude "* || " ${selected[*]} " == *" codex "* ]]; then
  if ! command -v git >/dev/null 2>&1; then
    echo "❌ git is not installed. Please install the Xcode Command Line Tools first."
    exit 1
  fi
  TMP_DIR=$(mktemp -d)
  echo "📥 Cloning Superpowers repository..."
  git clone --depth 1 --quiet "$SUPERPOWERS_REPO" "$TMP_DIR/superpowers"
  if [[ $? -ne 0 ]]; then
    echo "❌ Failed to clone $SUPERPOWERS_REPO"
    rm -rf "$TMP_DIR"
    exit 1
  fi
  SRC_DIR="$TMP_DIR/superpowers"
  echo "✅ Repository cloned ($(ls -1 "$SRC_DIR/skills" | wc -l | tr -d ' ') skills available)."
  echo
fi

# Copy every skill folder from the cloned repo into a target skills directory.
# Existing skill folders are left untouched (delete them and re-run to update).
copy_skills() {
  local target_dir="$1"
  local label="$2"
  local copied=0
  local skipped=0
  mkdir -p "$target_dir"
  for skill_path in "$SRC_DIR"/skills/*/; do
    local skill_name=$(basename "$skill_path")
    if [[ -d "$target_dir/$skill_name" ]]; then
      echo "   ⏭️  $skill_name (already present, skipped)"
      ((skipped++))
    else
      cp -R "${skill_path%/}" "$target_dir/"
      if [[ $? -ne 0 ]]; then
        echo "   ❌ Failed to copy $skill_name"
        return 1
      fi
      echo "   ✅ $skill_name"
      ((copied++))
    fi
  done
  echo "📌 $label: $copied copied, $skipped already present → $target_dir"
  return 0
}

overall_ok=true

# === 4. Install for Claude Code (copy into ~/.claude/skills) ===
if [[ " ${selected[*]} " == *" claude "* ]]; then
  echo "===== Claude Code ====="
  copy_skills "$CLAUDE_SKILLS_DIR" "Claude Code"
  if [[ $? -ne 0 ]]; then
    echo "❌ Claude Code installation failed."
    overall_ok=false
  fi
  echo
fi

# === 5. Install for Codex (copy into ~/.codex/skills) ===
if [[ " ${selected[*]} " == *" codex "* ]]; then
  echo "===== Codex ====="
  copy_skills "$CODEX_SKILLS_DIR" "Codex"
  if [[ $? -ne 0 ]]; then
    echo "❌ Codex installation failed."
    overall_ok=false
  fi
  echo
fi

# === 6. Install for OpenCode (manual prompt) ===
if [[ " ${selected[*]} " == *" opencode "* ]]; then
  echo "===== OpenCode ====="
  echo "📋 OpenCode has no headless install. Paste this prompt into an OpenCode session:"
  echo
  echo "   Fetch and follow instructions from $OPENCODE_INSTALL_URL"
  echo
  echo "   Alternative: add this entry to your opencode.json:"
  echo '   "plugin": ["superpowers@git+https://github.com/obra/superpowers.git"]'
  echo
  echo "   Then restart OpenCode and verify by asking: \"Tell me about your superpowers\""
  echo
fi

# === 7. Verify installations ===
echo "🧪 Verifying installations..."
verify_skills() {
  local target_dir="$1"
  local label="$2"
  local present=0
  local total=0
  for skill_path in "$SRC_DIR"/skills/*/; do
    ((total++))
    if [[ -f "$target_dir/$(basename "$skill_path")/SKILL.md" ]]; then
      ((present++))
    fi
  done
  if [[ $present -eq $total ]]; then
    echo "✅ $label: $present/$total Superpowers skills present in $target_dir"
  else
    echo "⚠️  $label: only $present/$total Superpowers skills found in $target_dir"
    overall_ok=false
  fi
}

if [[ " ${selected[*]} " == *" claude "* ]]; then
  verify_skills "$CLAUDE_SKILLS_DIR" "Claude Code"
fi
if [[ " ${selected[*]} " == *" codex "* ]]; then
  verify_skills "$CODEX_SKILLS_DIR" "Codex"
fi
if [[ " ${selected[*]} " == *" opencode "* ]]; then
  echo "ℹ️  OpenCode: manual step — verify inside OpenCode after following the prompt above."
fi

# === 8. Cleanup and wrap-up ===
if [[ -n "$TMP_DIR" ]]; then
  rm -rf "$TMP_DIR"
fi

echo
if [[ "$overall_ok" != true ]]; then
  echo "❌ Superpowers installation finished with errors. Please check the logs above."
  exit 1
fi

echo "💡 Next steps:"
echo "   • Restart your CLI sessions to pick up the new skills."
echo "   • Verify by asking: \"Tell me about your superpowers\""
echo "   • Update later: delete the skill folders and re-run this script."
echo "   • Docs: https://github.com/obra/superpowers"
echo
echo "🎉 Installation finished successfully!"
