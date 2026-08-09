#!/bin/zsh
# === wipe-skills.zsh ===
# Purpose: Wipe AI coding skills for Claude Code, Codex and OpenCode on macOS Tahoe
# Shell: Zsh (default)
# Author: theoneandonlywoj

echo "🧹 Starting skill wipe on macOS Tahoe..."
echo

# === 0. Configuration ===
SUPERPOWERS_SKILLS=(brainstorming dispatching-parallel-agents executing-plans finishing-a-development-branch receiving-code-review requesting-code-review subagent-driven-development systematic-debugging test-driven-development using-git-worktrees using-superpowers verification-before-completion writing-plans writing-skills)

CLAUDE_SKILLS_DIR="$HOME/.claude/skills"
CODEX_SKILLS_DIR="$HOME/.codex/skills"
OPENCODE_CONFIG="$HOME/.config/opencode/opencode.jsonc"
OPENCODE_PACKAGES_DIR="$HOME/.cache/opencode/packages"

# Script basename captured at top level: inside functions, $0 is the function
# name (zsh), not the script path.
me="${0:t}"

# === 1. Parse flags ===
typeset -a include_cli exclude_names
include_cli=()
exclude_names=()
exclude_superpowers=false
force=false
show_help=false
explicit_scope=false

usage() {
  echo "Usage: $me [options]"
  echo
  echo "Wipe AI coding skills for Claude Code, Codex and/or OpenCode."
  echo
  echo "Options:"
  echo "  --claude            Only wipe Claude Code skills"
  echo "  --codex             Only wipe Codex skills"
  echo "  --opencode          Only wipe the OpenCode superpowers plugin/cache"
  echo "  --all               Wipe all detected skills for all detected CLIs"
  echo "  --no-<skill>        Keep a specific skill (e.g. --no-graphify)"
  echo "  --no-superpowers    Keep the entire superpowers bundle (incl. OpenCode plugin)"
  echo "  --force             Skip the final confirmation prompt"
  echo "  -h, --help          Show this help message"
  echo
  echo "Without a --claude/--codex/--opencode/--all flag, runs interactively:"
  echo "detects skills, lists them, and asks which to delete."
  echo
  echo "Examples:"
  echo "  $me"
  echo "  $me --all --no-graphify"
  echo "  $me --claude --codex --no-superpowers --force"
}

for arg in "$@"; do
  case "$arg" in
    --claude)      include_cli+=("claude"); explicit_scope=true ;;
    --codex)       include_cli+=("codex"); explicit_scope=true ;;
    --opencode)    include_cli+=("opencode"); explicit_scope=true ;;
    --all)         include_cli=(claude codex opencode); explicit_scope=true ;;
    --no-superpowers) exclude_superpowers=true ;;
    --force)       force=true ;;
    -h|--help)     show_help=true ;;
    --no-*)        exclude_names+=("${arg#--no-}") ;;
    *)             echo "❌ Unknown option: $arg"; usage; exit 1 ;;
  esac
done

if [[ "$show_help" == true ]]; then
  usage
  exit 0
fi

# === 2. Detect CLIs ===
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
echo

if [[ ${#include_cli[@]} -eq 0 ]]; then
  if [[ ${#detected[@]} -eq 0 ]]; then
    echo "❌ None of the supported CLIs are installed."
    echo "   Nothing to wipe. Exiting."
    exit 0
  fi
  include_cli=("${detected[@]}")
fi

# === 3. Enumerate installed skills ===
# Each entry: "cli|name|full_path|kind" where kind is superpowers or custom
typeset -a entries
entries=()

is_superpowers_skill() {
  local name="$1"
  for s in "${SUPERPOWERS_SKILLS[@]}"; do
    if [[ "$name" == "$s" ]]; then
      return 0
    fi
  done
  return 1
}

# Validate that a skill name is safe before any deletion.
# Rejects "/", ".." and anything starting with "." (e.g. ".system", hidden dirs).
valid_skill_name() {
  local name="$1"
  [[ -n "$name" ]] || return 1
  [[ "$name" != */* ]] || return 1
  [[ "$name" != *".."* ]] || return 1
  [[ "$name" != .* ]] || return 1
  return 0
}

# Find skill dirs under a base dir. Only dirs containing SKILL.md count.
find_skills_in() {
  local cli="$1" base="$2"
  if [[ ! -d "$base" ]]; then
    echo "ℹ️  $cli: no skills directory at $base"
    return 0
  fi
  local found=false
  for dir in "$base"/*/(N); do
    [[ -d "$dir" ]] || continue
    local name="$(basename "$dir")"
    if ! valid_skill_name "$name"; then
      echo "⏭️  $cli: skipping unsafe/ignored entry: $name"
      continue
    fi
    if [[ ! -f "$dir/SKILL.md" ]]; then
      echo "⏭️  $cli: skipping $name (no SKILL.md)"
      continue
    fi
    local kind=custom
    if is_superpowers_skill "$name"; then
      kind=superpowers
    fi
    entries+=("$cli|$name|${dir%/}|$kind")
    found=true
  done
  if [[ "$found" == false ]]; then
    echo "ℹ️  $cli: no installable skills found in $base"
  fi
}

# OpenCode: superpowers arrive via the plugin; the cache dir is a superpowers bundle.
opencode_cache_dir=""
if [[ " ${include_cli[*]} " == *" opencode "* ]]; then
  for p in "$OPENCODE_PACKAGES_DIR"/superpowers@*(N); do
    if [[ -d "$p" ]]; then
      opencode_cache_dir="${p%/}"
      break
    fi
  done
  if [[ -n "$opencode_cache_dir" ]]; then
    entries+=("opencode|superpowers-bundle|$opencode_cache_dir|superpowers")
    echo "ℹ️  opencode: superpowers bundle cache found at $opencode_cache_dir"
  else
    echo "ℹ️  opencode: no superpowers package cache found"
  fi
fi

for cli in "${include_cli[@]}"; do
  case "$cli" in
    claude)   find_skills_in claude   "$CLAUDE_SKILLS_DIR" ;;
    codex)    find_skills_in codex    "$CODEX_SKILLS_DIR" ;;
  esac
done
echo

# === 4. Apply exclusions ===
typeset -a to_delete
to_delete=()

for entry in "${entries[@]}"; do
  IFS='|' read -r cli name skill_path kind <<< "$entry"
  if [[ "$name" == "superpowers-bundle" ]]; then
    if [[ "$exclude_superpowers" == true ]]; then
      echo "⏭️  $cli: skipping $name (--no-superpowers)"
      continue
    fi
    to_delete+=("$entry")
    continue
  fi
  skip=false
  for ex in "${exclude_names[@]}"; do
    if [[ "$name" == "$ex" ]]; then
      echo "⏭️  $cli: keeping $name (--no-$name)"
      skip=true
      break
    fi
  done
  [[ "$skip" == true ]] && continue
  if [[ "$exclude_superpowers" == true ]] && is_superpowers_skill "$name"; then
    echo "⏭️  $cli: keeping $name (--no-superpowers)"
    continue
  fi
  to_delete+=("$entry")
done
echo

if [[ ${#to_delete[@]} -eq 0 ]]; then
  echo "✅ Nothing to wipe."
  exit 0
fi

# === 5. Selection ===
# Interactive only when the user gave no CLI-scoping flags (default detected
# list). With explicit flags (--claude/--codex/--opencode/--all), delete all
# matched entries after confirmation.
interactive=false
if [[ "$explicit_scope" == false ]]; then
  interactive=true
fi

if [[ "$interactive" == true ]]; then
  echo "❓ Which entries do you want to wipe?"
  echo "   0) Cancel"
  i=1
  for entry in "${to_delete[@]}"; do
    IFS='|' read -r cli name skill_path kind <<< "$entry"
    echo "   $i) [$cli] $name ($kind)"
    ((i++))
  done
  echo "   a) All listed"
  echo -n "👉 Enter your choice (numbers, 'a', or '0'): "
  read choice
  if [[ "$choice" == [aA] ]]; then
    selected=("${to_delete[@]}")
  elif [[ "$choice" == "0" || -z "$choice" ]]; then
    echo "ℹ️  Cancelled. Nothing was wiped."
    exit 0
  else
    selected=()
    valid=true
    for tok in ${(z)choice}; do
      if [[ "$tok" == <-> ]] && (( tok >= 1 && tok <= ${#to_delete[@]} )); then
        selected+=("${to_delete[$tok]}")
      else
        valid=false
        break
      fi
    done
    if [[ "$valid" == false || ${#selected[@]} -eq 0 ]]; then
      echo "❌ Invalid choice. Nothing was wiped."
      exit 1
    fi
  fi
else
  selected=("${to_delete[@]}")
fi

if [[ ${#selected[@]} -eq 0 ]]; then
  echo "ℹ️  Nothing selected. Nothing was wiped."
  exit 0
fi

# === 6. Confirmation ===
echo
echo "🗑  The following will be PERMANENTLY deleted:"
for entry in "${selected[@]}"; do
  IFS='|' read -r cli name skill_path kind <<< "$entry"
  echo "   - [$cli] $name → $skill_path"
done
echo

if [[ "$force" == false ]]; then
  echo -n "👉 Continue and delete? (y/N): "
  read confirm
  if [[ "$confirm" != [yY] ]]; then
    echo "ℹ️  Cancelled. Nothing was wiped."
    exit 0
  fi
fi

# === 7. Wipe with safety guards ===
# Only ever delete paths that start with a known base AND came from the
# detected list. This is a belt-and-braces guard against rm -rf typos.
safe_base() {
  local skill_path="$1"
  case "$skill_path" in
    "$CLAUDE_SKILLS_DIR"/*) echo "$CLAUDE_SKILLS_DIR"; return 0 ;;
    "$CODEX_SKILLS_DIR"/*)  echo "$CODEX_SKILLS_DIR";  return 0 ;;
    "$OPENCODE_PACKAGES_DIR"/superpowers@*) echo "$OPENCODE_PACKAGES_DIR"; return 0 ;;
  esac
  return 1
}

wipe_dir() {
  local skill_path="$1" name="$2"
  local base
  base="$(safe_base "$skill_path")" || { echo "❌ Refusing to delete $skill_path (outside known bases)"; return 1; }
  # Resolve base and HOME to real paths so the prefix checks survive symlinked
  # parents (e.g. /var → /private/var on macOS).
  local resolved_base resolved_home
  resolved_base="$(cd "$base" 2>/dev/null && pwd -P)"
  resolved_home="$(cd "$HOME" 2>/dev/null && pwd -P)"
  local resolved
  resolved="$(cd "$(dirname "$skill_path")" 2>/dev/null && pwd -P)/$(basename "$skill_path")"
  if [[ -z "$resolved" || "$resolved" == "/" || "$resolved" == "$resolved_home" ]]; then
    echo "❌ Refusing to delete $resolved (unsafe path)"
    return 1
  fi
  if [[ -n "$resolved_base" && "$resolved" != "$resolved_base"/* ]]; then
    echo "❌ Refusing to delete $resolved (does not resolve under $resolved_base)"
    return 1
  fi
  echo "🗑  Removing $name: $resolved"
  rm -rf "$resolved"
  echo "   ✅ Removed"
}

# OpenCode: strip the superpowers plugin line from opencode.jsonc.
wipe_opencode_plugin() {
  if [[ ! -f "$OPENCODE_CONFIG" ]]; then
    echo "ℹ️  No opencode.jsonc found — skipping plugin cleanup."
    return 0
  fi
  if ! grep -q 'superpowers@git' "$OPENCODE_CONFIG"; then
    echo "ℹ️  No superpowers plugin entry in opencode.jsonc — nothing to strip."
    return 0
  fi
  local backup="$OPENCODE_CONFIG.backup_$(date +"%Y_%m_%d_%H_%M")"
  echo "💾 Backing up $OPENCODE_CONFIG to $backup"
  cp "$OPENCODE_CONFIG" "$backup"
  # Remove only lines that contain the superpowers plugin entry.
  grep -v 'superpowers@git' "$OPENCODE_CONFIG" > "$OPENCODE_CONFIG.tmp" || true
  if [[ -s "$OPENCODE_CONFIG.tmp" ]]; then
    mv "$OPENCODE_CONFIG.tmp" "$OPENCODE_CONFIG"
    echo "   ✅ Removed superpowers plugin entry from opencode.jsonc"
  else
    rm -f "$OPENCODE_CONFIG.tmp"
    echo "❌ Refusing to write an empty opencode.jsonc (backup preserved)."
    return 1
  fi
}

overall_ok=true

for entry in "${selected[@]}"; do
  IFS='|' read -r cli name skill_path kind <<< "$entry"
  case "$cli" in
    opencode)
      if [[ "$name" == "superpowers-bundle" ]]; then
        if [[ -d "$skill_path" ]]; then
          wipe_dir "$skill_path" "$name" || overall_ok=false
        fi
        if [[ "$exclude_superpowers" == false ]]; then
          wipe_opencode_plugin || overall_ok=false
        fi
      fi
      ;;
    claude|codex)
      wipe_dir "$skill_path" "$name" || overall_ok=false
      ;;
  esac
done

echo
if [[ "$overall_ok" == true ]]; then
  echo "🎉 Wipe complete."
else
  echo "⚠️  Wipe finished with errors — review the lines above."
  exit 1
fi

echo
echo "💡 Restore options:"
echo "   • Claude:  make csync   (re-syncs repo skills to ~/.claude/skills)"
echo "   • All:     ./skills/superpowers.zsh   (reinstalls superpowers bundle)"
echo "   • OpenCode: re-add the plugin line to opencode.jsonc and restart."
