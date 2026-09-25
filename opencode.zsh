#!/bin/zsh
# === opencode.zsh ===
# Purpose: Install OpenCode CLI, Desktop, and Open Dynamic Workflows on macOS Tahoe
# Shell: Zsh (default on macOS Tahoe)
# Author: theoneandonlywoj (style inspired)

setopt pipefail
autoload -Uz is-at-least

echo "🚀 Starting installation of OpenCode (open-source AI coding agent) on macOS Tahoe..."
echo

# === Configuration ===
install_cli="yes"
install_desktop="yes"
install_odw="yes"
opencode_app="/Applications/OpenCode.app"
opencode_path="$HOME/.opencode/bin/opencode"
opencode_releases_url="https://github.com/anomalyco/opencode/releases/latest"
odw_pkg="open-dynamic-workflows"
odw_bin="workflow"
odw_repo="imsai-sh/open-dynamic-workflows"
odw_skill_name="open-dynamic-workflows"
odw_project_root=$(git -C "${0:A:h}" rev-parse --show-toplevel 2>/dev/null)
odw_skill_dirs=(
  "$odw_project_root/.opencode/skills/$odw_skill_name"
  "$odw_project_root/.agents/skills/$odw_skill_name"
)

echo "📌 CLI install?        $install_cli"
echo "📌 Desktop install?    $install_desktop"
echo "📌 ODW install?        $install_odw"
echo "📂 Desktop path:       $opencode_app"
echo "📂 ODW skill scope:    ${odw_project_root:-repository not detected}"
echo

confirm_default_yes() {
  local reply
  read -r "reply?❓ $1 [Y/n] "
  [[ "$reply" != "n" && "$reply" != "N" ]]
}

newer_version_available() {
  local latest_version="$1"
  local current_version="$2"
  [[ -n "$latest_version" && -n "$current_version" && "$latest_version" != "$current_version" ]] && \
    ! is-at-least "$latest_version" "$current_version"
}

ensure_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    return 0
  fi

  echo "⚙️  Homebrew not found. Installing..."
  if ! /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
    echo "❌ Homebrew installation failed."
    return 1
  fi

  if [[ -x "/opt/homebrew/bin/brew" ]]; then
    if ! grep -Fq 'eval "$(/opt/homebrew/bin/brew shellenv)"' "$HOME/.zprofile" 2>/dev/null; then
      echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
    fi
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
  echo "✅ Homebrew installed."
}

install_opencode_cli() {
  echo "📥 Installing OpenCode CLI via official install script..."
  if curl -fsSL https://opencode.ai/install | bash; then
    export PATH="$HOME/.opencode/bin:$PATH"
    rehash
    return 0
  fi

  echo "⚠️  CLI install script failed. Trying Homebrew fallback..."
  ensure_homebrew || return 1
  if brew list --formula opencode >/dev/null 2>&1; then
    brew upgrade opencode
  else
    brew install anomalyco/tap/opencode
  fi
}

get_opencode_version() {
  local version_output
  version_output=$(opencode --version 2>/dev/null) || return 1
  version_output="${version_output##* }"
  echo "${version_output#v}"
}

get_latest_opencode_version() {
  local latest_url
  local latest_version
  latest_url=$(curl -fsSIL -o /dev/null -w '%{url_effective}' "$opencode_releases_url") || return 1
  latest_url="${latest_url%/}"
  latest_version="${latest_url##*/}"
  echo "${latest_version#v}"
}

find_odw_skill() {
  local skill_dir
  for skill_dir in "${odw_skill_dirs[@]}"; do
    if [[ -f "$skill_dir/SKILL.md" ]]; then
      echo "$skill_dir"
      return 0
    fi
  done
  return 1
}

# === 1. Install or update OpenCode CLI ===
if [[ "$install_cli" = "yes" ]]; then
  echo "===== CLI Installation ====="
  echo

  if ! command -v opencode >/dev/null 2>&1 && [[ -x "$opencode_path" ]]; then
    echo "⚙️  Adding $HOME/.opencode/bin to PATH for this session..."
    export PATH="$HOME/.opencode/bin:$PATH"
    rehash
  fi

  if command -v opencode >/dev/null 2>&1; then
    current_version=$(get_opencode_version 2>/dev/null || echo "unknown")
    echo "✅ OpenCode CLI is installed: $(command -v opencode)"
    echo "📌 Installed version:  $current_version"

    latest_version=$(get_latest_opencode_version 2>/dev/null || echo "unknown")
    echo "📌 Newest version:     $latest_version"

    if [[ "$current_version" = "unknown" || "$latest_version" = "unknown" ]]; then
      echo "⚠️  Could not compare OpenCode versions; leaving the current installation unchanged."
    elif newer_version_available "$latest_version" "$current_version"; then
      if confirm_default_yes "OpenCode $latest_version is available. Install it?"; then
        install_opencode_cli || {
          echo "❌ OpenCode CLI update failed."
          exit 1
        }
      else
        echo "⏭️  OpenCode update declined."
      fi
    else
      echo "✅ OpenCode CLI is up to date."
    fi
  else
    latest_version=$(get_latest_opencode_version 2>/dev/null || echo "unknown")
    echo "ℹ️  OpenCode CLI is not installed."
    echo "📌 Newest version:     $latest_version"
    install_opencode_cli || {
      echo "❌ OpenCode CLI installation failed."
      exit 1
    }
  fi

  if command -v opencode >/dev/null 2>&1; then
    echo "✅ OpenCode CLI ready: $(get_opencode_version 2>/dev/null || echo 'version unknown')"
  else
    echo "⚠️  OpenCode CLI not found in PATH. You may need to restart your terminal."
  fi
  echo
fi

# === 2. Install OpenCode Desktop ===
if [[ "$install_desktop" = "yes" ]]; then
  echo "===== Desktop App Installation ====="
  echo
  if [[ -d "$opencode_app" ]]; then
    echo "✅ OpenCode Desktop is already installed at $opencode_app"
  else
    ensure_homebrew || exit 1
    echo "📥 Installing OpenCode Desktop via Homebrew cask..."
    if ! brew install --cask opencode-desktop; then
      echo "❌ Homebrew cask install failed."
      exit 1
    fi
    echo "✅ OpenCode Desktop installed via Homebrew"
  fi
  echo
fi

# === 3. Install or update Open Dynamic Workflows ===
if [[ "$install_odw" = "yes" ]]; then
  echo "===== Open Dynamic Workflows ====="
  echo

  if [[ -z "$odw_project_root" ]]; then
    echo "❌ Cannot install the ODW skill because opencode.zsh is not inside a Git repository."
    exit 1
  fi

  if ! command -v node >/dev/null 2>&1; then
    echo "❌ Node.js is not installed. ODW requires Node.js 20 or newer."
    echo "   Install it first, e.g.: brew install node"
    exit 1
  fi

  node_version=$(node --version 2>/dev/null)
  node_version="${node_version#v}"
  node_major="${node_version%%.*}"
  if [[ -z "$node_major" || "$node_major" -lt 20 ]]; then
    echo "❌ ODW requires Node.js >= 20. Detected: ${node_version:-unknown}"
    exit 1
  fi
  echo "✅ Node.js v$node_version detected."

  if ! command -v npm >/dev/null 2>&1 || ! command -v npx >/dev/null 2>&1; then
    echo "❌ npm and npx are required to install ODW."
    exit 1
  fi
  echo "✅ npm $(npm --version 2>/dev/null || echo unknown) detected."

  odw_current_version=$(npm list -g "$odw_pkg" --depth=0 2>/dev/null | grep "$odw_pkg@" | head -n 1 | sed 's/.*@//')
  odw_latest_version=$(npm view "$odw_pkg" version 2>/dev/null || echo "unknown")

  if [[ -n "$odw_current_version" ]]; then
    echo "✅ ODW package is installed globally: $odw_pkg"
    echo "📌 Installed version:  $odw_current_version"
    echo "📌 Newest version:     $odw_latest_version"

    if [[ "$odw_latest_version" = "unknown" ]]; then
      echo "⚠️  Could not check the newest ODW version; leaving the package unchanged."
    elif newer_version_available "$odw_latest_version" "$odw_current_version"; then
      if confirm_default_yes "ODW $odw_latest_version is available. Install it?"; then
        if ! npm install -g "$odw_pkg"; then
          echo "❌ Failed to update $odw_pkg."
          exit 1
        fi
      else
        echo "⏭️  ODW update declined."
      fi
    else
      echo "✅ ODW package is up to date."
    fi
  else
    echo "ℹ️  ODW package is not installed globally."
    echo "📌 Newest version:     $odw_latest_version"
    echo "📥 Installing ODW CLI ($odw_pkg) via npm..."
    if ! npm install -g "$odw_pkg"; then
      echo "❌ Failed to install $odw_pkg globally."
      exit 1
    fi
  fi

  npm_global_bin="$(npm prefix -g 2>/dev/null)/bin"
  if ! command -v "$odw_bin" >/dev/null 2>&1 && [[ -x "$npm_global_bin/$odw_bin" ]]; then
    echo "⚙️  Adding $npm_global_bin to PATH for this session..."
    export PATH="$npm_global_bin:$PATH"
    rehash
  fi

  odw_skill_path=$(find_odw_skill 2>/dev/null || true)
  if [[ -n "$odw_skill_path" ]]; then
    echo "✅ ODW skill is already installed at $odw_skill_path"
  else
    echo "📥 Installing ODW skill for OpenCode..."
    typeset -a skill_install_args
    skill_install_args=(add "$odw_repo" --skill "$odw_skill_name" --agent opencode --yes)

    if ! (cd "$odw_project_root" && npx skills "${skill_install_args[@]}"); then
      echo "⚠️  Failed to install the ODW skill automatically."
      echo "   Try manually: npx skills add $odw_repo --skill $odw_skill_name --agent opencode"
    fi
  fi
  echo
  echo "ℹ️  Repository-local skill layout:"
  echo "   • .agents/skills/$odw_skill_name/ contains the skill and is officially discovered by OpenCode."
  echo "   • skills-lock.json stays at the repository root and records the skill source and content hash."
  echo "   • These paths are project-scoped, not global; .opencode/skills/ is also supported by OpenCode."
  echo "   • Commit .agents/ and skills-lock.json if clones of this repository should receive the skill."
  echo
fi

# === 4. Verification and wrap-up ===
echo "🧪 Verifying installation..."
echo

cli_ok=false
desktop_ok=false
odw_cli_ok=false
odw_skill_ok=false

if command -v opencode >/dev/null 2>&1; then
  echo "✅ OpenCode CLI: $(get_opencode_version 2>/dev/null || echo 'installed')"
  cli_ok=true
else
  echo "⚠️  OpenCode CLI not found in PATH. Try restarting your terminal."
fi

if [[ -d "$opencode_app" ]]; then
  echo "✅ OpenCode Desktop: installed at $opencode_app"
  desktop_ok=true
else
  echo "⚠️  OpenCode Desktop not found at $opencode_app"
fi

verified_odw_version=$(npm list -g "$odw_pkg" --depth=0 2>/dev/null | grep "$odw_pkg@" | head -n 1 | sed 's/.*@//')
if [[ -n "$verified_odw_version" ]] && command -v "$odw_bin" >/dev/null 2>&1; then
  echo "✅ ODW CLI: $odw_bin (package version: $verified_odw_version)"
  odw_cli_ok=true
else
  echo "⚠️  ODW CLI not found in PATH or its npm package is not installed."
fi

odw_skill_path=$(find_odw_skill 2>/dev/null || true)
if [[ -n "$odw_skill_path" ]]; then
  echo "✅ ODW skill: $odw_skill_path"
  odw_skill_ok=true
else
  echo "⚠️  ODW skill not found for OpenCode."
fi

echo
if [[ "$cli_ok" = true || "$desktop_ok" = true ]] && \
   [[ "$install_odw" != "yes" || ( "$odw_cli_ok" = true && "$odw_skill_ok" = true ) ]]; then
  echo "🎉 OpenCode and Open Dynamic Workflows installation complete!"
else
  echo "❌ Installation finished with missing components. Please check the logs above."
  exit 1
fi

echo
echo "💡 OpenCode quick start:"
echo "   • Authenticate a provider: opencode auth login"
echo "   • List authenticated providers: opencode auth list"
echo "   • List available models: opencode models"
echo "   • Start the TUI in this repository: opencode \"$odw_project_root\""
echo "   • Continue the last session: opencode --continue"
echo "   • Start in planning mode: opencode --agent plan"
echo "   • Run one non-interactive task: opencode run \"Review this repository\""
echo "   • Select a model: opencode --model provider/model"
echo "   • Prefer task-specific agents: fast/low-effort for discovery, stronger/high-effort for verification."
echo '   • Ask explicitly: Adapt the model, reasoning effort, and step budget to each subtask.'
echo "   • Launch Desktop via Spotlight (⌘ Space → 'OpenCode')"
echo
echo "🔐 Limit or enforce OpenCode behavior:"
echo "   • Put repository rules in: $odw_project_root/opencode.json"
echo "   • Use permission values: allow, ask, or deny. Specific rules override earlier wildcards."
echo "   • Limit nested subagents with subagent_depth; 0 disables subagent launches."
echo "   • Limit agent iterations with agent.<name>.steps."
echo "   • Configure each agent with model, steps, and provider-specific reasoningEffort."
echo "   • Give agents precise descriptions so OpenCode can route each task to the appropriate capability."
echo "   • Use subagent_depth: 1 or higher when task-specific agents should be invoked automatically."
echo "   • Reserve expensive models/high effort for ambiguous planning, verification, and final synthesis."
echo "   • Create a repository-only restricted agent:"
echo "     opencode agent create --path .opencode/agents/review.md --description \"Read-only review\" --mode primary --permissions read,glob,grep,skill"
echo "   • Example restrictive opencode.json:"
echo '     {'
echo '       "$schema": "https://opencode.ai/config.json",'
echo '       "subagent_depth": 0,'
echo '       "permission": {'
echo '         "*": "ask",'
echo '         "external_directory": "deny",'
echo '         "bash": {'
echo '           "*": "ask",'
echo '           "git status *": "allow",'
echo '           "git diff *": "allow",'
echo '           "rm *": "deny",'
echo '           "git push *": "deny"'
echo '         },'
echo '         "skill": {'
echo '           "*": "deny",'
echo '           "open-dynamic-workflows": "allow"'
echo '         }'
echo '       },'
echo '       "agent": { "build": { "steps": 10 } }'
echo '     }'
echo "   • Inspect the resolved configuration: opencode debug config"
echo "   • Permissions docs: https://opencode.ai/docs/permissions"
echo
echo "🌊 Open Dynamic Workflows quick start:"
echo "   • Restart OpenCode, then ask:"
echo '     Use the open-dynamic-workflows skill to write workflows/audit.js for this task.'
echo '     Bound fan-out and use fast models for discovery, stronger models for verification and synthesis.'
echo "   • Review the generated JavaScript before running it."
echo "   • Run it: $odw_bin run workflows/audit.js"
echo "   • Pass bounded input: $odw_bin run workflows/audit.js --args '{\"maxAgents\":4}'"
echo "   • Select the runtime model: $odw_bin run workflows/audit.js --model MODEL_ID"
echo "   • Treat --model as the default; override model inside each agent() call when tasks differ."
echo "   • Cancel with Ctrl-C; resume completed work with: $odw_bin run workflows/audit.js --resume RUN_ID"
echo "   • Run logs and saved scripts are stored in .workflow-runs/ by default."
echo
echo "🛡️  Limit or enforce workflow behavior:"
echo "   • Bound fan-out in workflow code; do not pass an unbounded list to parallel() or pipeline()."
echo '     const requested = Number(args.maxAgents ?? 4)'
echo '     const maxAgents = Math.max(1, Math.min(requested, 8))'
echo '     const selected = items.slice(0, maxAgents)'
echo "   • Route workflow tasks by complexity instead of using one model everywhere:"
echo "     const scan = await agent('Find candidates', { model: FAST_MODEL })"
echo "     const verdict = await agent('Verify candidates rigorously', { model: STRONG_MODEL })"
echo "     const result = await agent('Synthesize the final answer', { model: STRONG_MODEL })"
echo "     Replace FAST_MODEL and STRONG_MODEL with model IDs supported by the ODW executor."
echo "   • Enforce an output contract with agent(..., { schema: GATE }), then stop on failure:"
echo '     const GATE = {'
echo "       type: 'object', required: ['approved'], additionalProperties: false,"
echo "       properties: { approved: { type: 'boolean' } },"
echo '     }'
echo "     const verdict = await agent('Approve this stage', { schema: GATE })"
echo "     if (!verdict.approved) throw new Error('Workflow gate rejected')"
echo "   • Use normal JavaScript ordering and explicit checks to make later stages depend on a gate."
echo "   • phase() only labels progress; it does not enforce a boundary. Prompts alone are not enforcement."
echo "   • Use isolation: 'worktree' for concurrent edits; it is best-effort and falls back to the current cwd on failure."
echo "   • Current runtime defaults to max(1, min(16, CPU count - 2)) concurrent agents and enforces 1000 total."
echo "   • The current CLI has no concurrency, timeout, or token-budget flags. For lower runtime limits,"
echo "     call runWorkflow({ scriptPath: 'workflow.js', concurrency: 4, agentTimeoutMs: 300000 })."
echo "   • tokensSpent is reporting only; enforce cost limits by bounding agents and workflow loops."
echo "   • OpenCode permissions govern the host. They do not automatically propagate to ODW subprocesses."
echo "   • ODW $verified_odw_version uses Claude Code as its default executor (claude --print) with acceptEdits mode."
echo "     Its CLI has no permission-mode flag; --model uses a Claude model ID. Review workflows before execution."
echo "   • ODW $verified_odw_version supports per-agent model overrides but not per-agent reasoning-effort settings."
echo "     Express extra effort with stronger models and explicit verify/retry stages, or inject a custom executor."
echo
echo "📚 More information:"
echo "   • Run dock_cleanup.zsh to add OpenCode to your Dock"
echo "   • OpenCode docs: https://opencode.ai/docs"
echo "   • ODW skill: $odw_project_root/.agents/skills/$odw_skill_name/SKILL.md"
echo "   • ODW repo: https://github.com/$odw_repo"
