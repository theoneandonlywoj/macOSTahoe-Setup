#!/bin/zsh
# === herdr.zsh ===
# Purpose: Install Herdr (terminal agent multiplexer, https://herdr.dev) and set up integrations for installed coding agents on macOS Tahoe
# Shell: Zsh (default)
# Author: theoneandonlywoj

echo "🚀 Starting Herdr installation on macOS Tahoe..."
echo

# === 1. Check Homebrew installation ===
if ! command -v brew >/dev/null 2>&1; then
  echo "❌ Homebrew is not installed. Please run brew.zsh first."
  exit 1
fi
echo "✅ Homebrew detected."

# === 2. Install Herdr ===
echo
echo "📥 Installing Herdr via Homebrew..."
if command -v herdr >/dev/null 2>&1; then
  echo "✅ Herdr is already installed. Skipping installation."
else
  brew install herdr
  if [[ $? -ne 0 ]]; then
    echo "❌ Failed to install Herdr"
    exit 1
  fi
  echo "✅ Herdr installed."
fi

# === 3. Verify installation ===
echo
echo "🧪 Verifying installation..."

herdr_path=$(which herdr 2>/dev/null)
if [[ -z "$herdr_path" ]]; then
  echo "❌ Herdr not found in PATH."
  exit 1
fi
echo "📌 Herdr: $herdr_path"

herdr_version=$(herdr --version 2>/dev/null | head -1)
if [[ -n "$herdr_version" ]]; then
  echo "📌 Version: $herdr_version"
fi

# === 4. Seed default config (if missing) ===
echo
echo "📥 Checking Herdr config..."
herdr_config="$HOME/.config/herdr/config.toml"
if [[ -f "$herdr_config" ]]; then
  echo "✅ Config already exists at $herdr_config. Skipping."
else
  mkdir -p "$HOME/.config/herdr"
  if herdr --default-config > "$herdr_config" 2>/dev/null && [[ -s "$herdr_config" ]]; then
    echo "✅ Default config written to $herdr_config"
  else
    rm -f "$herdr_config"
    echo "⚠️  Could not generate default config (Herdr works without one)."
  fi
fi

# === 5. Set up integrations for installed coding agents ===
echo
echo "🔗 Detecting installed coding-agent CLIs..."

# Format: "herdr integration name|binary candidates (space-separated)|Display Name"
agent_integrations=(
  "claude|claude|Claude Code"
  "codex|codex|OpenAI Codex CLI"
  "cursor|cursor-agent|Cursor CLI"
  "opencode|opencode|OpenCode"
  "grok|grok|Grok CLI"
  "pi|pi|Pi"
  "kimi|kimi kimi-cli|Kimi CLI"
  "kilo|kilo kilocode|Kilo Code"
  "hermes|hermes|Hermes"
  "antigravity-cli|antigravity|Antigravity CLI"
)

configured_agents=()
warned_agents=()
declined_agents=()
skipped_agents=()

integration_status=$(herdr integration status 2>/dev/null)

for entry in "${agent_integrations[@]}"; do
  agent_name="${entry%%|*}"
  rest="${entry#*|}"
  agent_bins="${rest%%|*}"
  agent_label="${rest#*|}"

  found_bin=""
  for bin in ${=agent_bins}; do
    if command -v "$bin" >/dev/null 2>&1; then
      found_bin="$bin"
      break
    fi
  done

  if [[ -z "$found_bin" ]]; then
    echo "   ⏭️  Skipped $agent_label (CLI not found)"
    skipped_agents+=("$agent_label")
    continue
  fi

  if echo "$integration_status" | grep -q "^$agent_name: current"; then
    echo "   ✅ $agent_label integration already installed. Skipping."
    configured_agents+=("$agent_label")
    continue
  fi

  read "install_reply?   ❓ $agent_label detected ($found_bin). Install Herdr integration? [Y/n] "
  if [[ "$install_reply" == "n" || "$install_reply" == "N" ]]; then
    echo "   ⏭️  Declined $agent_label integration."
    declined_agents+=("$agent_label")
    continue
  fi

  install_output=$(herdr integration install "$agent_name" 2>&1)
  if [[ $? -eq 0 ]]; then
    echo "   ✅ $agent_label integration installed."
    configured_agents+=("$agent_label")
  else
    echo "   ⚠️  Could not install $agent_label integration:"
    echo "$install_output" | sed 's/^/      /'
    echo "      💡 If its config directory is missing, run '$found_bin' once and rerun this script."
    warned_agents+=("$agent_label")
  fi
done

# === 6. Report agents Herdr auto-detects with zero setup ===
echo
echo "ℹ️  Checking agents Herdr auto-detects with zero setup..."

# Format: "kind|binary candidates (space-separated)|Display Name"
agent_detect_only=(
  "gemini|gemini|Gemini CLI"
  "amp|amp|Amp"
  "cline|cline|Cline"
  "kiro|kiro|Kiro"
  "agy|agy|Agy"
  "maki|maki|Maki"
)

detected_only_agents=()
for entry in "${agent_detect_only[@]}"; do
  rest="${entry#*|}"
  agent_bins="${rest%%|*}"
  agent_label="${rest#*|}"

  for bin in ${=agent_bins}; do
    if command -v "$bin" >/dev/null 2>&1; then
      echo "   ✅ $agent_label detected — auto-detected by Herdr, no integration needed."
      detected_only_agents+=("$agent_label")
      break
    fi
  done
done
if [[ ${#detected_only_agents[@]} -eq 0 ]]; then
  echo "   ℹ️  None found."
fi

# === 7. Summary ===
echo
echo "═══════════════════════════════════════════════════"
echo "✨ Herdr setup complete!"
echo "═══════════════════════════════════════════════════"
echo
echo "🔗 Integrations configured:"
if [[ ${#configured_agents[@]} -gt 0 ]]; then
  for agent in "${configured_agents[@]}"; do
    echo "      • $agent"
  done
else
  echo "      (none)"
fi
echo
echo "⚠️  Needs attention:"
if [[ ${#warned_agents[@]} -gt 0 ]]; then
  for agent in "${warned_agents[@]}"; do
    echo "      • $agent"
  done
else
  echo "      (none)"
fi
echo
echo "⏭️  Declined by user:"
if [[ ${#declined_agents[@]} -gt 0 ]]; then
  for agent in "${declined_agents[@]}"; do
    echo "      • $agent"
  done
else
  echo "      (none)"
fi
echo
echo "⏭️  Not installed (skipped):"
if [[ ${#skipped_agents[@]} -gt 0 ]]; then
  for agent in "${skipped_agents[@]}"; do
    echo "      • $agent"
  done
else
  echo "      (none)"
fi
echo
echo "ℹ️  Zero-setup agents detected:"
if [[ ${#detected_only_agents[@]} -gt 0 ]]; then
  for agent in "${detected_only_agents[@]}"; do
    echo "      • $agent"
  done
else
  echo "      (none)"
fi

if [[ ${#warned_agents[@]} -gt 0 ]]; then
  echo
  echo "💡 If installs failed because the Herdr server was not running, start it and rerun:"
  echo "   brew services start herdr && ./herdr.zsh"
fi

# === 8. Wrap-up ===
echo
echo "✅ Herdr installed successfully!"
echo
echo "💡 Usage:"
echo "   • Start server (background service):  brew services start herdr"
echo "   • Start server (foreground):          herdr server"
echo "   • Create a workspace:                 herdr workspace create --cwd ~/project --label api"
echo "   • Create a tab:                       herdr tab create --label logs"
echo "   • Split a pane:                       herdr pane split 1-1 --direction right"
echo "   • Run a command in a pane:            herdr pane run 1-2 \"just test\""
echo "   • Attach to a remote box:             herdr --remote <host>"
echo "   • Check integration state:            herdr integration status"
echo "   • Rerun after adding a new agent CLI: ./herdr.zsh"
echo "   • Keyboard shortcuts:                 prefix is ctrl+b — press ctrl+b, then ? for the in-app list"
echo "   • Full shortcuts guide:               docs/guide_herdr_keyboard_shortcuts.md"
echo
echo "🎉 Installation finished successfully!"
