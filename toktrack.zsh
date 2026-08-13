#!/bin/zsh
# === toktrack.zsh ===
# Purpose: Install toktrack (persistent token & cost tracker TUI for AI coding CLIs, Rust) on macOS Tahoe
# Shell: Zsh (default on macOS Tahoe)
# Author: theoneandonlywoj (style inspired)
# Docs: https://github.com/mag123c/toktrack

echo "🔢  Starting toktrack installation on macOS Tahoe..."
echo

# === Configuration ===
toktrack_bin="toktrack"
cargo_bin_dir="$HOME/.cargo/bin"

echo "🔗 Binary:             $toktrack_bin"
echo "📂 Cargo bin dir:      $cargo_bin_dir"
echo

# === 1. Check if toktrack is already installed ===
if command -v "$toktrack_bin" >/dev/null 2>&1 || [[ -x "$cargo_bin_dir/$toktrack_bin" ]]; then
  current_version=$("$toktrack_bin" --version 2>/dev/null || echo "unknown")
  echo "✅ toktrack is already installed: $toktrack_bin (version: $current_version)"
  echo
  echo "💡 To update, run: cargo install --git https://github.com/mag123c/toktrack --force"
  echo "🎉 Nothing to do!"
  exit 0
fi

# === 2. Check and install Rust (Cargo) if missing ===
echo "📋 Checking prerequisite: Rust toolchain (Cargo)..."
echo

cargo_found=false
if command -v cargo >/dev/null 2>&1; then
  echo "✅ Cargo found: $(cargo --version)"
  cargo_found=true
elif command -v mise >/dev/null 2>&1 && mise exec -- cargo --version >/dev/null 2>&1; then
  echo "✅ Cargo found via Mise: $(mise exec -- cargo --version)"
  cargo_found=true
fi

if [[ "$cargo_found" = false ]]; then
  if ! command -v mise >/dev/null 2>&1; then
    echo "❌ Mise is not installed, and Cargo was not found."
    echo "   Please run ./mise.zsh first, then ./rust.zsh, then rerun this script."
    exit 1
  fi
  echo "⚙️  Cargo not found. Installing Rust via Mise..."
  mise install rust@stable
  if [[ $? -ne 0 ]]; then
    echo "❌ Failed to install Rust via Mise."
    echo "⚠️  Try running manually: mise install rust@stable && mise use -g rust@stable"
    exit 1
  fi
  mise use -g rust@stable
  echo "✅ Rust installed via Mise: $(mise exec -- rustc --version)"
fi
echo

# === 3. Install toktrack ===
echo "📥 Installing toktrack via Cargo (compiles from source, may take a few minutes)..."
if command -v cargo >/dev/null 2>&1; then
  cargo install --git https://github.com/mag123c/toktrack
else
  mise exec -- cargo install --git https://github.com/mag123c/toktrack
fi
install_status=$?

if [[ $install_status -ne 0 ]] && ! command -v "$toktrack_bin" >/dev/null 2>&1 && [[ ! -x "$cargo_bin_dir/$toktrack_bin" ]]; then
  echo "❌ toktrack install failed (cargo install)."
  echo "⚠️  Try running manually: cargo install --git https://github.com/mag123c/toktrack"
  exit 1
fi

# === 4. Ensure Cargo bin dir is on PATH ===
if ! command -v "$toktrack_bin" >/dev/null 2>&1 && [[ -x "$cargo_bin_dir/$toktrack_bin" ]]; then
  echo "✅ toktrack installed successfully."
  export PATH="$cargo_bin_dir:$PATH"
  if ! grep -q "$cargo_bin_dir" ~/.zshrc 2>/dev/null; then
    echo "💡 Adding Cargo bin dir to ~/.zshrc..."
    echo '' >> ~/.zshrc
    echo "# Rust/Cargo binaries (toktrack)" >> ~/.zshrc
    echo "export PATH=\"$cargo_bin_dir:\$PATH\"" >> ~/.zshrc
  fi
  echo "✅ Cargo bin dir added to PATH."
else
  echo "✅ toktrack installed successfully."
fi
echo

# === 5. Verify installation ===
echo "🧪 Verifying installation..."
echo

if command -v "$toktrack_bin" >/dev/null 2>&1 || [[ -x "$cargo_bin_dir/$toktrack_bin" ]]; then
  installed_version=$("$toktrack_bin" --version 2>/dev/null || echo "unknown")
  echo "✅ toktrack: $toktrack_bin (version: $installed_version)"
else
  echo "⚠️  toktrack not found in PATH. Open a new terminal and run: $toktrack_bin --version"
  exit 1
fi

echo
echo "🎉 toktrack installation complete!"
echo
echo "💡 Next steps:"
echo "   • Launch TUI dashboard:       $toktrack_bin            (or: npx toktrack)"
echo "   • Today's usage:              $toktrack_bin daily"
echo "   • Weekly summary:             $toktrack_bin weekly"
echo "   • Monthly summary:            $toktrack_bin monthly"
echo "   • Statistics:                 $toktrack_bin stats"
echo "   • Shareable receipt:          $toktrack_bin report --svg"
echo "   • Data-preservation audit:    $toktrack_bin audit"
echo "   • JSON output (scripting):    $toktrack_bin daily --json"
echo

# === 6. CLI use-cases ===
echo "🛠️  CLI use-cases:"
echo "   # Track Claude Code, Codex, OpenCode, PI Agent, Gemini, Qwen, Copilot, Antigravity in one dashboard"
echo "   $toktrack_bin"
echo "   # OpenAI/Anthropic billing windows"
echo "   $toktrack_bin daily"
echo "   $toktrack_bin weekly"
echo "   $toktrack_bin monthly"
echo "   # Export per-source stats"
echo "   $toktrack_bin stats --json"
echo "   # Generate a shareable usage receipt (PDF/SVG shareable)"
echo "   $toktrack_bin report"
echo "   $toktrack_bin report --month"
echo "   $toktrack_bin report --svg"
echo "   # Check what history survived Claude Code's 30-day cleanup"
echo "   $toktrack_bin audit"
echo "   # TUI tabs: 1 Overview · 2 Stats · 3 Models · 4 Projects · 5 Audit (d/w/m = day/week/month)"
echo

# === 7. Notes & configuration ===
echo "📂 Configuration:"
echo "   • Supported CLIs: Claude Code (~/.claude/projects), Codex (~/.codex/sessions),"
echo "     OpenCode (~/.local/share/opencode/storage/message), PI Agent (~/.pi/agent/sessions),"
echo "     Gemini, Qwen, GitHub Copilot CLI, Antigravity"
echo "   • Persistent cache in ~/.toktrack/cache - history survives CLI log cleanup (30-day Claude deletion)"
echo "   • Costs from LiteLLM list-price (offline bundled snapshot fallback); ~ marks estimates"
echo "   • Custom pricing: ~/.toktrack/pricing.toml"
echo "   • Remote Codex sources: ~/.toktrack/config.toml or 'toktrack remote add <name> <host>'"
echo "   • Env overrides: CLAUDE_CONFIG_DIR, CODEX_HOME, OPENCODE_DATA_DIR, PI_AGENT_DIR, etc."
echo "   • Rust toolchain is managed by Mise: mise ls rust / mise install rust@<ver>"
echo "   • Cargo installs to ~/.cargo/bin (should already be on PATH)"
echo "   • Updates: cargo install --git https://github.com/mag123c/toktrack --force"
echo "   • No-toolchain option: npx toktrack     • Homebrew: brew tap mag123c/toktrack && brew install toktrack"
echo "   • Pre-built binaries: https://github.com/mag123c/toktrack/releases"
echo "   • Docs: https://github.com/mag123c/toktrack"
echo
echo "▶️  Run: $toktrack_bin"