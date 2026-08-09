#!/bin/zsh
# === matt-pocock-engineering.zsh ===
# Purpose: Install Matt Pocock's engineering skills for Claude Code, Codex and OpenCode on macOS Tahoe
# Shell: Zsh (default)
# Author: theoneandonlywoj

echo "🚀 Starting Matt Pocock engineering skills installation on macOS Tahoe..."
echo

# === 0. Configuration ===
MATT_SKILLS_REPO="https://github.com/mattpocock/skills.git"
MATT_ENGINEERING_DIR="skills/engineering"
CLAUDE_SKILLS_DIR="$HOME/.claude/skills"
CODEX_SKILLS_DIR="$HOME/.codex/skills"
OPENCODE_SKILLS_DIR="$HOME/.config/opencode/skills"

# === 1. Detect supported CLIs ===
echo "🔍 Detecting supported CLIs..."
typeset -a detected
detected=()
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
  echo "   Install one first and re-run this script."
  exit 1
fi
echo

# === 2. Ask which CLI(s) to install for ===
echo "❓ Which CLI(s) do you want to install Matt Pocock's engineering skills for?"
i=1
for cli in "${detected[@]}"; do
  echo "   $i) $cli"
  ((i++))
done
echo "   a) all detected"

typeset -a selected
selected=()
while true; do
  echo -n "👉 Enter your choice (e.g. '1', '1 2', or 'a'): "
  if ! read choice; then
    echo
    echo "❌ No selection received. Exiting."
    exit 1
  fi
  if [[ "$choice" == [aA] ]]; then
    selected=("${detected[@]}")
    break
  fi

  selected=()
  valid=true
  for token in ${(z)choice}; do
    if [[ "$token" == <-> ]] && (( token >= 1 && token <= ${#detected[@]} )); then
      selected+=("${detected[$token]}")
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
echo "📌 Installing engineering skills for: ${selected[*]}"
echo

# === 3. Clone the repository ===
if ! command -v git >/dev/null 2>&1; then
  echo "❌ git is not installed. Please install the Xcode Command Line Tools first."
  exit 1
fi

tmp_dir="$(mktemp -d)"
if [[ -z "$tmp_dir" || ! -d "$tmp_dir" ]]; then
  echo "❌ Failed to create a temporary directory."
  exit 1
fi

cleanup_done=false
cleanup_failed=false
cleanup() {
  [[ "$cleanup_done" == true ]] && return 0
  cleanup_done=true
  if [[ -n "$tmp_dir" && -d "$tmp_dir" ]]; then
    if ! rm -rf "$tmp_dir"; then
      echo "❌ Failed to remove temporary directory: $tmp_dir" >&2
      cleanup_failed=true
    fi
  fi
}
trap cleanup EXIT INT TERM

echo "📥 Cloning Matt Pocock's skills repository..."
if ! git clone --depth 1 --quiet "$MATT_SKILLS_REPO" "$tmp_dir/repository"; then
  echo "❌ Failed to clone $MATT_SKILLS_REPO"
  exit 1
fi

source_dir="$tmp_dir/repository/$MATT_ENGINEERING_DIR"
if [[ ! -d "$source_dir" ]]; then
  echo "❌ Engineering skills directory not found at $MATT_ENGINEERING_DIR"
  exit 1
fi

# === 4. Enumerate engineering skills ===
typeset -a skill_dirs skill_names
skill_dirs=()
skill_names=()
for skill_dir in "$source_dir"/*(/N); do
  [[ -d "$skill_dir" ]] || continue
  skill_name="${skill_dir:t}"
  if [[ ! -f "$skill_dir/SKILL.md" ]]; then
    echo "⏭️  Skipping $skill_name (no SKILL.md)"
    continue
  fi
  skill_dirs+=("${skill_dir%/}")
  skill_names+=("$skill_name")
done

if [[ ${#skill_dirs[@]} -eq 0 ]]; then
  echo "❌ No engineering skills with SKILL.md were found."
  exit 1
fi
echo "✅ Found ${#skill_dirs[@]} engineering skills."
echo

# Copy every engineering skill folder into a target global skills directory.
copy_skills() {
  local target_dir="$1"
  local label="$2"
  local copied=0
  local skipped=0

  if ! mkdir -p "$target_dir"; then
    echo "❌ Failed to create $target_dir"
    return 1
  fi

  for index in {1..${#skill_dirs[@]}}; do
    local skill_dir="${skill_dirs[$index]}"
    local skill_name="${skill_names[$index]}"
    local destination="$target_dir/$skill_name"

    if [[ -d "$destination" ]]; then
      echo "   ⏭️  $skill_name (already present, skipped)"
      ((skipped++))
      continue
    fi
    if [[ -e "$destination" || -L "$destination" ]]; then
      echo "   ❌ $skill_name conflicts with an existing non-directory at $destination"
      return 1
    fi
    if ! cp -R "$skill_dir" "$target_dir/"; then
      echo "   ❌ Failed to copy $skill_name"
      return 1
    fi
    echo "   ✅ $skill_name"
    ((copied++))
  done
  echo "📌 $label: $copied copied, $skipped already present → $target_dir"
  return 0
}

verify_skills() {
  local target_dir="$1"
  local label="$2"
  local present=0

  for skill_name in "${skill_names[@]}"; do
    if [[ -f "$target_dir/$skill_name/SKILL.md" ]]; then
      ((present++))
    else
      echo "   ❌ $label: missing $skill_name/SKILL.md"
    fi
  done
  if [[ $present -eq ${#skill_names[@]} ]]; then
    echo "✅ $label: $present/${#skill_names[@]} engineering skills present in $target_dir"
    return 0
  fi
  echo "⚠️  $label: only $present/${#skill_names[@]} engineering skills found in $target_dir"
  return 1
}

# === 5. Install for selected CLIs ===
overall_ok=true
for cli in "${selected[@]}"; do
  case "$cli" in
    claude)
      echo "===== Claude Code ====="
      copy_skills "$CLAUDE_SKILLS_DIR" "Claude Code" || overall_ok=false
      echo
      ;;
    codex)
      echo "===== Codex ====="
      copy_skills "$CODEX_SKILLS_DIR" "Codex" || overall_ok=false
      echo
      ;;
    opencode)
      echo "===== OpenCode ====="
      copy_skills "$OPENCODE_SKILLS_DIR" "OpenCode" || overall_ok=false
      echo
      ;;
  esac
done

# === 6. Verify installations ===
echo "🧪 Verifying installations..."
for cli in "${selected[@]}"; do
  case "$cli" in
    claude)   verify_skills "$CLAUDE_SKILLS_DIR" "Claude Code" || overall_ok=false ;;
    codex)    verify_skills "$CODEX_SKILLS_DIR" "Codex" || overall_ok=false ;;
    opencode) verify_skills "$OPENCODE_SKILLS_DIR" "OpenCode" || overall_ok=false ;;
  esac
done

echo
cleanup
if [[ "$cleanup_failed" == true ]]; then
  overall_ok=false
fi
if [[ "$overall_ok" != true ]]; then
  echo "❌ Matt Pocock engineering skills installation finished with errors."
  exit 1
fi

echo "💡 Next steps:"
echo "   • Restart your CLI sessions to load the new skills."
echo "   • Run /setup-matt-pocock-skills once in each repository before using the engineering workflows."
echo "   • To update later, remove the skill folders you want refreshed and re-run this script."
echo "   • Docs: https://github.com/mattpocock/skills"
echo
echo "🎉 Installation finished successfully!"
