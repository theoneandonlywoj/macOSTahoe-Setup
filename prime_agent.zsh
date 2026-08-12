#!/bin/zsh
# === prime_agent.zsh ===
# Purpose: Install Prime Agent (AI coding agent from Prime Intellect) on macOS Tahoe
# Shell: Zsh (default on macOS Tahoe)
# Author: theoneandonlywoj (style inspired)
# Docs: https://github.com/PrimeIntellect-ai/prime-agent

echo "🚀 Starting Prime Agent installation on macOS Tahoe..."
echo

# === Configuration ===
prime_agent_bin="prime-agent"
prime_agent_url="https://app.primeintellect.ai/prime-agent/install.sh"
release_channel="stable"   # use "beta" to install the latest build from main

echo "🔗 Binary:             $prime_agent_bin"
echo "🌐 Installer:          $prime_agent_url"
echo "📦 Release channel:    $release_channel"
echo

# === 1. Check if Prime Agent is already installed ===
if command -v "$prime_agent_bin" >/dev/null 2>&1; then
  current_version=$("$prime_agent_bin" --version 2>/dev/null || echo "unknown")
  echo "✅ Prime Agent is already installed: $prime_agent_bin (version: $current_version)"
  echo
  echo "💡 To update, rerun this script or use the official installer:"
  echo "   curl -fsSL $prime_agent_url | sh"
  echo "🎉 Nothing to do!"
  exit 0
fi

# === 2. Check and install Node.js 20.6.0+ and npm (required) ===
echo "📋 Checking prerequisites: Node.js 20.6.0+ and npm..."
echo

node_ok=false
if command -v node >/dev/null 2>&1; then
  node_version=$(node --version 2>/dev/null | tr -d 'v')
  if node -e 'const [m,n]=process.versions.node.split(".").map(Number); process.exit(m>20||(m===20&&n>=6)?0:1)' >/dev/null 2>&1; then
    echo "✅ Node.js found: v$node_version (20.6.0+ required)"
    node_ok=true
  else
    echo "⚠️  Node.js found but too old: v$node_version (20.6.0+ required)"
  fi
else
  echo "⚙️  Node.js not found."
fi

if command -v npm >/dev/null 2>&1; then
  echo "✅ npm found: $(npm --version 2>/dev/null)"
else
  echo "⚠️  npm not found."
fi

if [[ "$node_ok" = false ]]; then
  echo
  echo "⚙️  Installing Node.js via Homebrew..."
  if ! command -v brew >/dev/null 2>&1; then
    echo "⚙️  Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo "💡 Adding Homebrew to PATH..."
    if [[ -d "/opt/homebrew/bin" ]]; then
      echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    echo "✅ Homebrew installed."
  else
    echo "✅ Homebrew already installed."
  fi

  if brew list node &>/dev/null; then
    brew upgrade node
  else
    brew install node
  fi

  if ! command -v node >/dev/null 2>&1 || ! node -e 'const [m,n]=process.versions.node.split(".").map(Number); process.exit(m>20||(m===20&&n>=6)?0:1)' >/dev/null 2>&1; then
    echo "❌ Node.js 20.6.0+ is required. Please install it and rerun this script."
    exit 1
  fi
  echo "✅ Node.js installed: $(node --version)"
fi

# === 3. Install Prime Agent ===
echo
echo "📥 Installing Prime Agent (official installer, npm global install)..."
if [[ "$release_channel" = "beta" ]]; then
  curl -fsSL "$prime_agent_url" | sh -s -- beta
else
  curl -fsSL "$prime_agent_url" | sh
fi
install_status=$?

prime_agent_found=false
if command -v "$prime_agent_bin" >/dev/null 2>&1; then
  prime_agent_found=true
fi

if [[ $install_status -ne 0 ]] && [[ "$prime_agent_found" = false ]]; then
  echo "❌ Prime Agent install failed (official installer)."
  echo "⚠️  Try running manually: curl -fsSL $prime_agent_url | sh"
  exit 1
fi

# === 4. Ensure npm global bin is on PATH ===
if command -v "$prime_agent_bin" >/dev/null 2>&1; then
  echo "✅ Prime Agent installed successfully."
else
  npm_global_bin=$(npm bin -g 2>/dev/null || npm prefix -g 2>/dev/null)
  if [[ -n "$npm_global_bin" ]] && [[ -x "$npm_global_bin/$prime_agent_bin" ]]; then
    echo "⚙️  Adding npm global bin to PATH for this session: $npm_global_bin"
    export PATH="$npm_global_bin:$PATH"
    if ! grep -q "$npm_global_bin" ~/.zshrc 2>/dev/null; then
      echo "💡 Adding npm global bin to ~/.zshrc..."
      echo '' >> ~/.zshrc
      echo "# Prime Agent (npm global bin)" >> ~/.zshrc
      echo "export PATH=\"$npm_global_bin:\$PATH\"" >> ~/.zshrc
    fi
    echo "✅ Prime Agent installed successfully."
  else
    echo "⚠️  Prime Agent not found in PATH. You may need to restart your terminal."
  fi
fi
echo

# === 5. Verify installation ===
echo "🧪 Verifying installation..."
echo

if command -v "$prime_agent_bin" >/dev/null 2>&1; then
  installed_version=$("$prime_agent_bin" --version 2>/dev/null || echo "unknown")
  echo "✅ Prime Agent: $prime_agent_bin (version: $installed_version)"
else
  echo "⚠️  Prime Agent not found in PATH. Open a new terminal and run: $prime_agent_bin --version"
  exit 1
fi

echo
echo "🎉 Prime Agent installation complete!"
echo
echo "💡 Next steps:"
echo "   • Authenticate: run prime-agent in a project directory, then use /login"
echo "   • Or set an API key first: export ANTHROPIC_API_KEY=sk-ant-... && prime-agent"
echo "   • Start it in any project: cd ~/my-project && prime-agent"
echo "   • Docs: https://github.com/PrimeIntellect-ai/prime-agent"
echo

# === 6. CLI use-cases ===
echo "🛠️  CLI use-cases:"
echo "   prime-agent                       # Interactive mode in the current project"
echo "   prime-agent -p \"Summarize this\"   # One-shot prompt, prints and exits"
echo "   cat README.md | prime-agent -p \"Summarize this text\""
echo "   prime-agent -c                    # Continue the most recent session"
echo "   prime-agent -r                    # Browse/resume previous sessions"
echo "   prime-agent @file.ts \"Review it\"  # Reference files with @"
echo "   prime-agent --model openai/gpt-4o # Pick provider/model per run"
echo "   prime-agent --mode json           # JSON event output for scripting"
echo "   prime-agent agents                # Inspect/reattach to active runs"
echo "   prime-agent package install <src> # Install skills/extensions packages"
echo "   prime-agent config                # Enable/disable resources"
echo "   prime-agent doctor --fix          # Diagnose and fix setup issues"
echo

# === 7. Shortcuts ===
echo "⌨️  Key shortcuts:"
echo "   Ctrl+L        Switch model"
echo "   Ctrl+P        Cycle scoped models"
echo "   Ctrl+T        Toggle thinking blocks"
echo "   Enter         Submit (queues a steering message while agent works)"
echo "   Alt+Enter     Queue a follow-up message"
echo "   Ctrl+C        Interrupt current operation (press again to exit)"
echo "   Esc           Clear input / close menus"
echo "   Tab           Path completion"
echo "   Shift+Enter   New line (multi-line input)"
echo "   Ctrl+G        Edit prompt in external editor (\$VISUAL or \$EDITOR)"
echo "   Ctrl+V        Paste an image"
echo "   Ctrl+O        Expand/collapse tool output"
echo "   !cmd          Run a shell command and send output to the model"
echo "   !!cmd         Run a shell command without sending output"
echo "   Type / or /hotkeys to see all slash commands and shortcuts"
echo

# === 8. Slash commands ===
echo "📋 Useful slash commands:"
echo "   /login  /logout      Manage credentials"
echo "   /model  /effort      Switch model / reasoning level"
echo "   /settings            Thinking level, theme, delivery, transport"
echo "   /new  /resume        New session / pick a previous session"
echo "   /tree  /fork  /clone Session branching"
echo "   /compact             Summarize older messages to free context"
echo "   /usage  /context     Token, cost, and context breakdown"
echo "   /btw <q>  /side <q>  Inline side question without polluting session"
echo "   /reload              Reload keybindings, extensions, skills, prompts"
echo "   /export  /share      Export session to HTML / share as gist"
echo "   /quit                Quit Prime Agent"
echo

# === 9. Configuration locations ===
echo "📂 Configuration locations:"
echo "   Config dir:            ~/.prime/agent/   (override: PRIME_AGENT_CODING_AGENT_DIR)"
echo "   Settings:              ~/.prime/agent/settings.json   (packages, models, providers)"
echo "   Credentials:           ~/.prime/agent/auth.json       (API keys from /login)"
echo "   Sessions:              ~/.prime/agent/sessions/       (auto-saved session history)"
echo "   Global instructions:   ~/.prime/agent/AGENTS.md"
echo "   System prompt:         ~/.prime/agent/SYSTEM.md   (append: APPEND_SYSTEM.md)"
echo "   Keybindings:           ~/.prime/agent/keybindings.json"
echo "   Project instructions:  AGENTS.md or CLAUDE.md (current + parent directories)"
echo "   Project settings:      .prime/agent/settings.json   (shareable with your team)"
echo "   Project system prompt: .prime/agent/SYSTEM.md"
echo
echo "🧩 Skills, commands & extensions:"
echo "   Skills:    'prime-agent package install <npm|git|path>' then use /skill:name"
echo "   Commands:  extensions register custom slash commands; prompt templates via /templatename"
echo "   Resources: packages bundle skills/ (SKILL.md), extensions/, prompts/, themes/"
echo "   Manage:    'prime-agent package list' and 'prime-agent config' to enable/disable"
echo "   Global installs -> ~/.prime/agent/; --local flag -> project .prime/agent/"
echo
echo "🧠 RLM subagents (recursive delegation state & runtime):"
echo "   Kernel runtime:     ~/.prime/agent/kernel-venv/   (Python 3.11 + ipykernel + rlm)"
echo "   State ledger:       ~/.prime/agent/session-artifacts/<session-id>/harness/harness_state.json"
echo "   Global ledger:      ~/.prime/agent/harness/   (prompt notes, memories, skill refs)"
echo "   Session artifacts:  ~/.prime/agent/session-artifacts/<session-id>/"
echo "                       (kernel-state.dill, kernel-state.json, scheduled-jobs.json)"
echo "   Child transcripts:  ~/.prime/agent/session-artifacts/<session-id>/sub-xxxxxxxx/<child-session-id>.jsonl"
echo "   Use rlm in IPython: await rlm(\"subtask\", name=\"reviewer\")   # list: await rlm.list_subagents()"
echo
echo "▶️  Run: cd ~/my-project && prime-agent"
