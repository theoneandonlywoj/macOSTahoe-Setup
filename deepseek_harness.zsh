#!/bin/zsh
# === deepseek_harness.zsh ===
# Purpose: Install DeepSeek Harness (open-source agent harness) from source on macOS Tahoe
# Shell: Zsh (default on macOS Tahoe)
# Author: theoneandonlywoj (style inspired)
# Docs: https://github.com/deepseek-ai/deepseek-harness

echo "🤖 Starting installation of DeepSeek Harness from source on macOS Tahoe..."
echo

# === Configuration ===
dsh_bin="dsh"
dsh_repo="https://github.com/deepseek-ai/deepseek-harness.git"
dsh_branch="master"
dsh_plugin_guide="https://github.com/deepseek-ai/deepseek-harness/blob/master/docs/user/develop/basic/index.md"
dsh_plugin_example="https://github.com/liustack/modlens"
dsh_install_dir="$HOME/.local/share/deepseek-harness"
dsh_bin_dir="$HOME/.local/bin"
dsh_path="$dsh_bin_dir/$dsh_bin"

echo "🔗 Binary:             $dsh_bin"
echo "🌐 Repository:         $dsh_repo"
echo "🌿 Release branch:     $dsh_branch"
echo "📂 Source checkout:    $dsh_install_dir"
echo "📂 Launcher:           $dsh_path"
echo "📦 pnpm:               repository-pinned version"
echo

# DeepSeek Harness supports Node.js 22.19+ on the Node 22 line, or Node.js 24+.
node_is_supported() {
  command -v node >/dev/null 2>&1 || return 1
  node -e '
    const [major, minor] = process.versions.node.split(".").map(Number)
    process.exit((major === 22 && minor >= 19) || major >= 24 ? 0 : 1)
  ' >/dev/null 2>&1
}

git_is_supported() {
  command -v git >/dev/null 2>&1 || return 1

  local version remainder major minor
  version=$(git --version 2>/dev/null)
  version=${version#git version }
  version=${version%% *}
  major=${version%%.*}
  remainder=${version#*.}
  minor=${remainder%%.*}

  [[ "$major" = <-> && "$minor" = <-> ]] || return 1
  (( major > 2 || (major == 2 && minor >= 26) ))
}

ensure_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    echo "✅ Homebrew already installed."
    return 0
  fi

  if [[ -x "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    echo "✅ Homebrew found at /opt/homebrew/bin/brew."
    return 0
  fi

  if [[ -x "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
    echo "✅ Homebrew found at /usr/local/bin/brew."
    return 0
  fi

  echo "⚙️  Homebrew not found. Installing..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ $? -ne 0 ]]; then
    echo "❌ Homebrew installation failed."
    return 1
  fi

  if [[ -x "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  else
    echo "❌ Homebrew was installed but could not be found."
    return 1
  fi

  echo "✅ Homebrew installed."
}

# === 1. Check if DeepSeek Harness is already installed ===
export PATH="$dsh_bin_dir:$PATH"
existing_dsh=""
if [[ -x "$dsh_path" && ! -d "$dsh_path" ]]; then
  existing_dsh="$dsh_path"
elif command -v "$dsh_bin" >/dev/null 2>&1; then
  existing_dsh=$(command -v "$dsh_bin")
fi

if [[ -n "$existing_dsh" ]]; then
  current_version=$("$existing_dsh" --version 2>/dev/null || echo "unknown")
  echo "✅ DeepSeek Harness is already installed: $existing_dsh (version: $current_version)"
  if [[ -d "$dsh_install_dir/.git" ]]; then
    echo "📂 Existing source checkout: $dsh_install_dir"
  fi
  echo
  read "reinstall_reply?❓ Reinstall the newest DeepSeek Harness source version? (y/N) "
  reinstall_reply="${reinstall_reply:l}"
  if [[ "$reinstall_reply" != "y" && "$reinstall_reply" != "yes" ]]; then
    echo
    echo "💡 Custom plugin guide: $dsh_plugin_guide"
    echo "   # open \"$dsh_plugin_guide\""
    echo "💡 Third-party example plugin (ModLens): $dsh_plugin_example"
    echo "   # open \"$dsh_plugin_example\""
    echo "🎉 Keeping the existing installation."
    exit 0
  fi
  echo
  echo "🔄 Reinstalling DeepSeek Harness from the newest $dsh_branch source..."
fi

if [[ -e "$dsh_install_dir" && ! -d "$dsh_install_dir/.git" ]]; then
  echo "❌ Installation target already exists and is not a Git checkout:"
  echo "   $dsh_install_dir"
  echo "   Move or remove it, then rerun this script."
  exit 1
fi

# === 2. Check and install Git 2.26+ ===
echo "📋 Checking prerequisite: Git 2.26+..."
if git_is_supported; then
  echo "✅ Git found: $(git --version)"
else
  if command -v git >/dev/null 2>&1; then
    echo "⚠️  Git is too old: $(git --version 2>/dev/null || echo 'unknown')"
  else
    echo "⚙️  Git not found."
  fi

  ensure_homebrew || exit 1
  echo "⚙️  Installing current Git via Homebrew..."
  if brew list --formula git >/dev/null 2>&1; then
    brew upgrade git
  else
    brew install git
  fi

  git_prefix=$(brew --prefix git 2>/dev/null)
  if [[ -n "$git_prefix" ]]; then
    export PATH="$git_prefix/bin:$PATH"
  fi

  if ! git_is_supported; then
    echo "❌ Git 2.26+ is required. Install it and rerun this script."
    exit 1
  fi
  echo "✅ Git installed: $(git --version)"
fi
echo

# === 3. Check and install supported Node.js and npm ===
echo "📋 Checking prerequisites: Node.js 22.19+ or 24+, and npm..."
node_ok=false
if node_is_supported; then
  echo "✅ Supported Node.js found: $(node --version)"
  node_ok=true
elif command -v node >/dev/null 2>&1; then
  echo "⚠️  Unsupported Node.js found: $(node --version 2>/dev/null || echo 'unknown')"
else
  echo "⚙️  Node.js not found."
fi

if command -v npm >/dev/null 2>&1; then
  echo "✅ npm found: $(npm --version 2>/dev/null)"
else
  echo "⚠️  npm not found."
fi

if [[ "$node_ok" = false ]] || ! command -v npm >/dev/null 2>&1; then
  echo
  ensure_homebrew || exit 1
  echo "⚙️  Installing current Node.js via Homebrew..."
  if brew list --formula node >/dev/null 2>&1; then
    brew upgrade node
  else
    brew install node
  fi

  node_prefix=$(brew --prefix node 2>/dev/null)
  if [[ -n "$node_prefix" ]]; then
    export PATH="$node_prefix/bin:$PATH"
  fi

  if ! node_is_supported || ! command -v npm >/dev/null 2>&1; then
    echo "❌ DeepSeek Harness requires Node.js 22.19+ on Node 22, or Node.js 24+."
    echo "   Node.js 23 is not supported. Install a supported version and rerun this script."
    exit 1
  fi
  echo "✅ Node.js installed: $(node --version)"
  echo "✅ npm installed: $(npm --version)"
fi
echo

# === 4. Clone or update the DeepSeek Harness repository ===
if [[ -d "$dsh_install_dir/.git" ]]; then
  echo "📂 Existing DeepSeek Harness checkout found."

  checkout_origin=$(git -C "$dsh_install_dir" remote get-url origin 2>/dev/null)
  if [[ -z "$checkout_origin" ]]; then
    echo "❌ Existing checkout has no origin remote: $dsh_install_dir"
    exit 1
  fi

  if [[ -n "$(git -C "$dsh_install_dir" status --porcelain 2>/dev/null)" ]]; then
    echo "❌ Existing checkout contains local changes."
    echo "   Review, commit, stash, or discard them before reinstalling:"
    echo "   # git -C \"$dsh_install_dir\" status --short"
    exit 1
  fi

  echo "📥 Fetching the newest source from origin..."
  if ! git -C "$dsh_install_dir" fetch --prune origin; then
    echo "❌ Failed to fetch updates from $checkout_origin"
    exit 1
  fi

  if git -C "$dsh_install_dir" show-ref --verify --quiet "refs/heads/$dsh_branch"; then
    git -C "$dsh_install_dir" switch "$dsh_branch"
  else
    git -C "$dsh_install_dir" switch --create "$dsh_branch" --track "origin/$dsh_branch"
  fi
  if [[ $? -ne 0 ]]; then
    echo "❌ Failed to check out the $dsh_branch branch."
    exit 1
  fi

  if ! git -C "$dsh_install_dir" merge --ff-only "origin/$dsh_branch"; then
    echo "❌ The local $dsh_branch branch cannot be fast-forwarded to origin/$dsh_branch."
    echo "   Resolve the local branch state manually, then rerun this script."
    exit 1
  fi
  echo "✅ Source updated to: $(git -C "$dsh_install_dir" rev-parse --short HEAD)"
else
  echo "📥 Cloning DeepSeek Harness..."
  mkdir -p "${dsh_install_dir:h}"
  git clone --depth 1 --branch "$dsh_branch" "$dsh_repo" "$dsh_install_dir"
  if [[ $? -ne 0 ]]; then
    echo "❌ Failed to clone $dsh_repo"
    exit 1
  fi
  echo "✅ Repository cloned to $dsh_install_dir"
fi
echo

# === 5. Enable the repository-pinned pnpm version ===
pnpm_required=$(node -e '
  const fs = require("node:fs")
  const manifest = JSON.parse(fs.readFileSync(process.argv[1], "utf8"))
  const packageManager = manifest.packageManager
  if (typeof packageManager !== "string" || !packageManager.startsWith("pnpm@")) process.exit(1)
  process.stdout.write(packageManager.slice("pnpm@".length).split("+")[0])
' "$dsh_install_dir/package.json" 2>/dev/null)

if [[ $? -ne 0 || -z "$pnpm_required" ]]; then
  echo "❌ Could not determine the required pnpm version from package.json."
  exit 1
fi

echo "📦 Preparing pnpm $pnpm_required..."
mkdir -p "$dsh_bin_dir"
export PATH="$dsh_bin_dir:$PATH"

pnpm_ok=false
if command -v pnpm >/dev/null 2>&1; then
  installed_pnpm=$(cd "$dsh_install_dir" && pnpm --version 2>/dev/null)
  if [[ "$installed_pnpm" = "$pnpm_required" ]]; then
    echo "✅ pnpm found: $installed_pnpm"
    pnpm_ok=true
  fi
fi

if [[ "$pnpm_ok" = false ]] && command -v corepack >/dev/null 2>&1; then
  echo "⚙️  Enabling pnpm through Corepack..."
  corepack enable --install-directory "$dsh_bin_dir"
  corepack prepare "pnpm@$pnpm_required" --activate
  if [[ $? -eq 0 ]]; then
    installed_pnpm=$(cd "$dsh_install_dir" && pnpm --version 2>/dev/null)
    if [[ "$installed_pnpm" = "$pnpm_required" ]]; then
      pnpm_ok=true
    fi
  fi
fi

if [[ "$pnpm_ok" = false ]]; then
  echo "⚙️  Corepack setup unavailable; installing pnpm via npm..."
  npm install -g "pnpm@$pnpm_required"
  if [[ $? -ne 0 ]]; then
    echo "❌ Failed to install pnpm $pnpm_required."
    exit 1
  fi

  npm_global_bin=$(npm bin -g 2>/dev/null)
  if [[ -z "$npm_global_bin" ]]; then
    npm_global_prefix=$(npm prefix -g 2>/dev/null)
    npm_global_bin="$npm_global_prefix/bin"
  fi
  if [[ -n "$npm_global_bin" ]]; then
    export PATH="$npm_global_bin:$PATH"
  fi

  installed_pnpm=$(cd "$dsh_install_dir" && pnpm --version 2>/dev/null)
  if [[ "$installed_pnpm" = "$pnpm_required" ]]; then
    pnpm_ok=true
  fi
fi

if [[ "$pnpm_ok" = false ]]; then
  echo "❌ pnpm $pnpm_required is required, but found: ${installed_pnpm:-not found}"
  exit 1
fi
echo "✅ pnpm ready: $installed_pnpm"
echo

# === 6. Install dependencies and build from source ===
echo "📥 Installing dependencies and refreshing workspace links..."
echo "🏗️  Building DeepSeek Harness (this may take a while)..."
if ! (cd "$dsh_install_dir" && pnpm install && pnpm run build); then
  echo "❌ DeepSeek Harness dependency installation or build failed."
  echo "⚠️  Retry manually:"
  echo "   # cd \"$dsh_install_dir\""
  echo "   # pnpm install"
  echo "   # pnpm run build"
  exit 1
fi

if [[ ! -f "$dsh_install_dir/apps/cli/lib/bin.js" ]]; then
  echo "❌ Build completed without the expected CLI artifact:"
  echo "   $dsh_install_dir/apps/cli/lib/bin.js"
  exit 1
fi
echo "✅ DeepSeek Harness built successfully."
echo

# === 7. Create a global dsh launcher ===
echo "🔗 Creating launcher at $dsh_path..."
export PATH="$dsh_bin_dir:$PATH"
if [[ -d "$dsh_path" ]]; then
  echo "❌ The launcher path is a directory: $dsh_path"
  echo "   Move or remove it, then rerun this script."
  exit 1
fi

dsh_launcher_tmp="$dsh_path.tmp.$$"
cat > "$dsh_launcher_tmp" <<EOF
#!/bin/zsh
exec node "$dsh_install_dir/apps/cli/lib/bin.js" "\$@"
EOF
if [[ $? -ne 0 ]]; then
  echo "❌ Failed to write the dsh launcher."
  rm -f "$dsh_launcher_tmp"
  exit 1
fi

chmod +x "$dsh_launcher_tmp"
if [[ $? -ne 0 ]] || ! mv -f "$dsh_launcher_tmp" "$dsh_path"; then
  echo "❌ Failed to install the dsh launcher at $dsh_path"
  rm -f "$dsh_launcher_tmp"
  exit 1
fi

if [[ ! -x "$dsh_path" ]]; then
  echo "❌ Failed to create the dsh launcher at $dsh_path"
  exit 1
fi
echo "✅ Launcher created."

touch "$HOME/.zprofile"
if ! grep -Fqx 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.zprofile" 2>/dev/null; then
  echo >> "$HOME/.zprofile"
  echo '# User-local command-line tools' >> "$HOME/.zprofile"
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zprofile"
  echo "✅ Added $dsh_bin_dir to PATH in ~/.zprofile"
else
  echo "✅ $dsh_bin_dir is already configured in ~/.zprofile"
fi
rehash
echo

# === 8. Verify installation ===
echo "🧪 Verifying installation..."
installed_version=$("$dsh_path" --version 2>/dev/null)
if [[ $? -ne 0 || -z "$installed_version" ]]; then
  echo "❌ DeepSeek Harness verification failed."
  echo "   Try in a new terminal: dsh --version"
  exit 1
fi
echo "✅ DeepSeek Harness: $dsh_path (version: $installed_version)"
resolved_dsh=$(command -v "$dsh_bin" 2>/dev/null)
if [[ "$resolved_dsh" != "$dsh_path" ]]; then
  echo "⚠️  The current shell resolves dsh to: ${resolved_dsh:-not found}"
  echo "   Open a new terminal so $dsh_path takes precedence."
else
  echo "✅ Active command link: $resolved_dsh"
fi

echo
echo "🎉 DeepSeek Harness source installation complete!"
echo "⚠️  DeepSeek Harness is a developer preview and may introduce breaking changes."
echo
echo "💡 Next steps:"
echo "   • Start in a project: cd ~/my-project && dsh web"
echo "   • Open the Web UI: http://127.0.0.1:3080"
echo "   • Configure a model: Settings → Models"
echo "   • Docs: https://github.com/deepseek-ai/deepseek-harness"
echo "   • Custom plugin guide: $dsh_plugin_guide"
echo "   • Third-party example plugin (ModLens): $dsh_plugin_example"
echo

# === 9. Commented runtime and profile commands ===
echo "🛠️  Runtime and profile command reference:"
echo "   # Start the Web UI with the current directory as the workspace"
echo "   # cd ~/my-project && dsh web"
echo "   # Use another Web UI port"
echo "   # dsh web --port 8080"
echo "   # Run one headless task"
echo '   # dsh --profile headless "summarize this project"'
echo "   # Show launcher help and version"
echo "   # dsh --help"
echo "   # dsh --version"
echo "   # Inspect the default or effective Web profile configuration"
echo "   # dsh --profile web --dump-default-config"
echo "   # dsh --profile web --dump-config"
echo "   # Install or remove a profile plugin"
echo "   # dsh plugin --profile <name> add <package-or-git-spec>"
echo "   # dsh plugin --profile <name> remove <package>"
echo

# === 10. Commented developer commands ===
echo "🧑‍💻 Source development command reference:"
echo "   # Enter the source checkout"
echo "   # cd \"$dsh_install_dir\""
echo "   # Install dependencies and build artifacts"
echo "   # pnpm install"
echo "   # pnpm run build"
echo "   # Run focused development checks"
echo "   # pnpm run typecheck"
echo "   # pnpm run lint"
echo "   # pnpm run test"
echo "   # Run broader project gates"
echo "   # pnpm run test:coverage"
echo "   # pnpm run test:e2e"
echo "   # pnpm run test:snapshot"
echo "   # pnpm run hygiene"
echo "   # pnpm run doc-sync"
echo "   # pnpm run website:build"
echo "   # Run source demos (require DEEPSEEK_API_KEY)"
echo "   # pnpm run demo:cordis"
echo "   # pnpm run demo:acp"
echo "   # Open the tutorial for creating and loading a custom plugin"
echo "   # open \"$dsh_plugin_guide\""
echo "   # Open a third-party example DeepSeek Harness plugin repository (ModLens)"
echo "   # open \"$dsh_plugin_example\""
echo

# === 11. Commented configuration options ===
echo "⚙️  Configuration reference:"
echo "   # DeepSeek API credentials and optional custom endpoint"
echo '   # export DEEPSEEK_API_KEY="sk-..."'
echo '   # export DEEPSEEK_BASE_URL="https://api.deepseek.com"'
echo "   # Override the Harness home directory (default: ~/.dsh)"
echo '   # export DSH_HOME="$HOME/.dsh"'
echo "   # Select native tools, code-mode tools, or both"
echo '   # export DSH_TOOLS_MODE="native"  # native, code, or both'
echo "   # Keep session telemetry disabled explicitly"
echo "   # export DSH_TELEMETRY_DISABLED=1"
echo "   # Let supported Node.js versions honor HTTP_PROXY and HTTPS_PROXY"
echo "   # export NODE_USE_ENV_PROXY=1"
echo "   # Optional custom DeepSeek search endpoint"
echo '   # export DEEPSEEK_SEARCH_BASE_URL="https://search.example.com"'
echo
echo "📂 Configuration locations:"
echo "   # User settings"
echo "   # ~/.dsh/settings.yaml"
echo "   # Write-only credentials managed by the Web UI"
echo "   # ~/.dsh/.credentials.yaml"
echo "   # Harness-wide environment and patch layer"
echo "   # ~/.dsh/.env"
echo "   # ~/.dsh/cordis.patch.yml"
echo "   # Per-profile manifest and patch layer"
echo "   # ~/.dsh/profiles/<name>/package.json"
echo "   # ~/.dsh/profiles/<name>/cordis.patch.yml"
echo "   # Project environment and agent instructions"
echo "   # <project>/.env"
echo "   # <project>/AGENTS.md"
echo "   # <project>/CLAUDE.md"
echo

# === 12. Commented update commands ===
echo "⬆️  Source update reference:"
echo "   # Review local changes before updating"
echo "   # git -C \"$dsh_install_dir\" status --short"
echo "   # Pull, reinstall dependencies, and rebuild"
echo "   # cd \"$dsh_install_dir\""
echo "   # git pull --ff-only"
echo "   # pnpm install"
echo "   # pnpm run build"
echo
echo "▶️  Run: cd ~/my-project && dsh web"
