#!/bin/zsh
# === executor.zsh ===
# Purpose: Install Executor (open-source MCP gateway — one tool catalog shared across every coding agent, https://executor.sh) and connect installed coding agents on macOS Tahoe
# Shell: Zsh (default)
# Author: theoneandonlywoj
# Docs: https://executor.sh/docs

echo "🚀 Starting Executor installation on macOS Tahoe..."
echo

# === Configuration ===
executor_bin="executor"
executor_port="${EXECUTOR_PORT:-4788}"                      # loopback-only port of the local daemon
executor_mcp_url="http://127.0.0.1:${executor_port}/mcp"     # streamable HTTP MCP endpoint
executor_web_url="http://127.0.0.1:${executor_port}"
executor_app="/Applications/Executor.app"
mcp_server_name="executor"
claude_mcp_scope="user"                                     # user = available in all projects; "project" writes a shared .mcp.json

echo "🔗 Binary:             $executor_bin"
echo "🔗 MCP endpoint:       $executor_mcp_url"
echo "🌐 Web UI:             $executor_web_url"
echo "📂 Desktop app:        $executor_app (optional)"
echo

# === 1. Check Homebrew installation ===
if ! command -v brew >/dev/null 2>&1; then
  echo "❌ Homebrew is not installed. Please run brew.zsh first."
  exit 1
fi
echo "✅ Homebrew detected."

# === 2. Check Node.js 20+ and npm (required by the Executor CLI) ===
echo
echo "📋 Checking prerequisites: Node.js 20+ and npm..."

node_ok=false
if command -v node >/dev/null 2>&1; then
  node_version=$(node --version 2>/dev/null | tr -d 'v')
  if node -e 'process.exit(Number(process.versions.node.split(".")[0]) >= 20 ? 0 : 1)' >/dev/null 2>&1; then
    echo "✅ Node.js found: v$node_version (20+ required)"
    node_ok=true
  else
    echo "⚠️  Node.js found but too old: v$node_version (20+ required)"
  fi
else
  echo "⚙️  Node.js not found."
fi

if [[ "$node_ok" = false ]]; then
  echo "⚙️  Installing Node.js via Homebrew..."
  if brew list node &>/dev/null; then
    brew upgrade node
  else
    brew install node
  fi
  if ! command -v node >/dev/null 2>&1 || ! node -e 'process.exit(Number(process.versions.node.split(".")[0]) >= 20 ? 0 : 1)' >/dev/null 2>&1; then
    echo "❌ Node.js 20+ is required. Please install it and rerun this script."
    exit 1
  fi
  echo "✅ Node.js installed: $(node --version)"
fi

if ! command -v npm >/dev/null 2>&1; then
  echo "❌ npm not found (it ships with Node.js). Please fix your Node.js install and rerun."
  exit 1
fi
echo "✅ npm found: $(npm --version 2>/dev/null)"

# === 3. Install Executor CLI ===
echo
echo "📥 Installing Executor CLI via npm..."
if command -v "$executor_bin" >/dev/null 2>&1; then
  echo "✅ Executor CLI is already installed. Skipping installation."
  echo "💡 To update, run: npm update -g executor"
else
  npm install -g executor
  if [[ $? -ne 0 ]]; then
    echo "❌ Failed to install Executor CLI"
    echo "⚠️  Try running manually: npm install -g executor"
    exit 1
  fi
  echo "✅ Executor CLI installed."
fi

# === 4. Verify installation ===
echo
echo "🧪 Verifying installation..."

executor_path=$(which "$executor_bin" 2>/dev/null)
if [[ -z "$executor_path" ]]; then
  echo "❌ Executor not found in PATH."
  echo "💡 Check your npm global bin dir: npm bin -g   (or: npm prefix -g)"
  exit 1
fi
echo "📌 Executor: $executor_path"

executor_version=$("$executor_bin" --version 2>/dev/null | head -1)
if [[ -n "$executor_version" ]]; then
  echo "📌 Version: $executor_version"
fi

# === 5. Install the background service (launchd-supervised daemon) ===
echo
echo "⚙️  Checking Executor background service..."
service_status=$("$executor_bin" service status 2>&1)
if [[ $? -eq 0 ]] && echo "$service_status" | grep -qi "running"; then
  echo "✅ Executor service is already installed and running. Skipping."
else
  echo "📥 Installing Executor as an OS-supervised background service (port $executor_port)..."
  "$executor_bin" install --port "$executor_port"
  if [[ $? -ne 0 ]]; then
    echo "⚠️  Could not install the background service."
    echo "   Executor still works: every CLI command auto-starts the daemon on demand."
    echo "   Try manually: executor install --port $executor_port"
  else
    echo "✅ Executor service installed."
  fi
fi

echo
echo "🧪 Daemon status:"
"$executor_bin" daemon status 2>&1 | sed 's/^/   /'

# === 6. Optional: Executor Desktop app (Homebrew cask) ===
echo
echo "🖥️  Executor Desktop app (companion GUI for the same local daemon)..."
desktop_installed=false
if [[ -d "$executor_app" ]]; then
  echo "✅ Executor Desktop is already installed at $executor_app. Skipping."
  desktop_installed=true
else
  read "desktop_reply?   ❓ Install Executor Desktop via Homebrew cask? [Y/n] "
  if [[ "$desktop_reply" == "n" || "$desktop_reply" == "N" ]]; then
    echo "   ⏭️  Skipped Executor Desktop."
  else
    brew install --cask executor
    if [[ $? -ne 0 ]]; then
      echo "   ⚠️  Could not install Executor Desktop. Try manually: brew install --cask executor"
    else
      echo "   ✅ Executor Desktop installed."
      desktop_installed=true
    fi
  fi
fi

# === 7. Connect installed coding agents to the Executor MCP endpoint ===
echo
echo "🔗 Detecting installed coding-agent CLIs..."

# Format: "method|binary candidates (space-separated)|Display Name"
#   claude  → claude mcp add   (streamable HTTP)
#   codex   → codex mcp add    (stdio: executor mcp)
#   gemini  → gemini mcp add   (streamable HTTP)
#   add-mcp → npx add-mcp      (auto-detects & writes the client's MCP config)
agent_integrations=(
  "claude|claude|Claude Code"
  "codex|codex|OpenAI Codex CLI"
  "gemini|gemini|Gemini CLI"
  "add-mcp|cursor-agent cursor|Cursor"
  "add-mcp|opencode|OpenCode"
)

configured_agents=()
warned_agents=()
declined_agents=()
skipped_agents=()
add_mcp_pending=()

for entry in "${agent_integrations[@]}"; do
  method="${entry%%|*}"
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

  # Already registered?
  case "$method" in
    claude)
      if claude mcp list 2>/dev/null | grep -q "^$mcp_server_name:"; then
        echo "   ✅ $agent_label already has the Executor MCP server. Skipping."
        configured_agents+=("$agent_label")
        continue
      fi
      ;;
    codex)
      if codex mcp list 2>/dev/null | grep -qw "$mcp_server_name"; then
        echo "   ✅ $agent_label already has the Executor MCP server. Skipping."
        configured_agents+=("$agent_label")
        continue
      fi
      ;;
    gemini)
      if gemini mcp list 2>/dev/null | grep -qw "$mcp_server_name"; then
        echo "   ✅ $agent_label already has the Executor MCP server. Skipping."
        configured_agents+=("$agent_label")
        continue
      fi
      ;;
  esac

  read "install_reply?   ❓ $agent_label detected ($found_bin). Connect it to Executor? [Y/n] "
  if [[ "$install_reply" == "n" || "$install_reply" == "N" ]]; then
    echo "   ⏭️  Declined $agent_label connection."
    declined_agents+=("$agent_label")
    continue
  fi

  case "$method" in
    claude)
      install_output=$(claude mcp add --transport http --scope "$claude_mcp_scope" "$mcp_server_name" "$executor_mcp_url" 2>&1)
      install_status=$?
      ;;
    codex)
      install_output=$(codex mcp add "$mcp_server_name" -- "$executor_bin" mcp 2>&1)
      install_status=$?
      ;;
    gemini)
      install_output=$(gemini mcp add --transport http "$mcp_server_name" "$executor_mcp_url" 2>&1)
      install_status=$?
      ;;
    add-mcp)
      add_mcp_pending+=("$agent_label")
      continue
      ;;
  esac

  if [[ $install_status -eq 0 ]]; then
    echo "   ✅ $agent_label connected to Executor."
    configured_agents+=("$agent_label")
  else
    echo "   ⚠️  Could not connect $agent_label:"
    echo "$install_output" | sed 's/^/      /'
    warned_agents+=("$agent_label")
  fi
done

# add-mcp handles the remaining clients (Cursor, OpenCode, ...) in one interactive pass
if [[ ${#add_mcp_pending[@]} -gt 0 ]]; then
  echo
  echo "📥 Running add-mcp for: ${(j:, :)add_mcp_pending}"
  echo "   (add-mcp detects installed MCP clients and writes the Executor entry into each config)"
  npx -y add-mcp "$executor_mcp_url" --transport http --name "$mcp_server_name"
  if [[ $? -eq 0 ]]; then
    for agent in "${add_mcp_pending[@]}"; do
      echo "   ✅ $agent connected to Executor (via add-mcp)."
      configured_agents+=("$agent")
    done
  else
    for agent in "${add_mcp_pending[@]}"; do
      echo "   ⚠️  add-mcp did not finish for $agent."
      warned_agents+=("$agent")
    done
    echo "      💡 Retry: npx add-mcp $executor_mcp_url --transport http --name $mcp_server_name"
    echo "      💡 Or stdio: npx add-mcp \"executor mcp\" --name $mcp_server_name"
  fi
fi

# === 8. Summary ===
echo
echo "═══════════════════════════════════════════════════"
echo "✨ Executor setup complete!"
echo "═══════════════════════════════════════════════════"
echo
echo "🔗 Agents connected:"
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
echo "🖥️  Desktop app:"
if [[ "$desktop_installed" = true ]]; then
  echo "      • $executor_app"
else
  echo "      (not installed — brew install --cask executor)"
fi

if [[ ${#warned_agents[@]} -gt 0 ]]; then
  echo
  echo "💡 If connections failed because the daemon was not reachable, restart it and rerun:"
  echo "   executor service restart && ./executor.zsh"
fi

# === 9. Wrap-up ===
echo
echo "✅ Executor installed successfully!"
echo
echo "💡 Usage:"
echo "   • Open the web UI:                    executor web        ($executor_web_url)"
echo "   • Run daemon in the foreground:       executor web --foreground"
echo "   • Service status / restart / remove:  executor service status | restart | uninstall"
echo "   • Daemon status / stop:               executor daemon status | stop"
echo "   • Add an integration (web UI):        Add Source → paste an OpenAPI, GraphQL or MCP URL"
echo "   • Add an integration (CLI):           executor call executor openapi addSource '{\"spec\":\"<url>\",\"namespace\":\"<name>\",\"baseUrl\":\"<url>\"}'"
echo "   • List integrations:                  executor tools integrations"
echo "   • Search tools by intent:             executor tools search \"send email\""
echo "   • Call a tool:                        executor call github issues create '{\"title\":\"Hi\"}'"
echo "   • Resume a paused execution:          executor resume --execution-id exec_123"
echo "   • MCP endpoint for any client:        $executor_mcp_url   (or stdio: executor mcp)"
echo "   • Sign in to Executor Cloud:          executor login"
echo "   • Zsh completions:                    executor --completions zsh > ~/.zsh/completions/_executor"
echo "   • Rerun after adding a new agent CLI: ./executor.zsh"
echo "   • Docs:                               https://executor.sh/docs"
echo
echo "🎉 Installation finished successfully!"
