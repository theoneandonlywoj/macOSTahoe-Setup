#!/bin/zsh
# === livediff.zsh ===
# Purpose: Install Livediff (live terminal diff TUI, Rust) on macOS Tahoe
# Shell: Zsh (default on macOS Tahoe)
# Author: theoneandonlywoj (style inspired)
# Docs: https://github.com/SoCkEt7/Livediff

echo "👁️  Starting Livediff installation on macOS Tahoe..."
echo

# === Configuration ===
livediff_bin="livediff"
cargo_bin_dir="$HOME/.cargo/bin"

echo "🔗 Binary:             $livediff_bin"
echo "📂 Cargo bin dir:      $cargo_bin_dir"
echo

# === 1. Check if Livediff is already installed ===
if command -v "$livediff_bin" >/dev/null 2>&1 || [[ -x "$cargo_bin_dir/$livediff_bin" ]]; then
  current_version=$("$livediff_bin" --version 2>/dev/null || echo "unknown")
  echo "✅ Livediff is already installed: $livediff_bin (version: $current_version)"
  echo
  echo "💡 To update, run: cargo install livediff --force"
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

# === 3. Install Livediff ===
echo "📥 Installing Livediff via Cargo (compiles from source, may take a few minutes)..."
if command -v cargo >/dev/null 2>&1; then
  cargo install livediff
else
  mise exec -- cargo install livediff
fi
install_status=$?

if [[ $install_status -ne 0 ]] && ! command -v "$livediff_bin" >/dev/null 2>&1 && [[ ! -x "$cargo_bin_dir/$livediff_bin" ]]; then
  echo "❌ Livediff install failed (cargo install)."
  echo "⚠️  Try running manually: cargo install livediff"
  exit 1
fi

# === 4. Ensure Cargo bin dir is on PATH ===
if ! command -v "$livediff_bin" >/dev/null 2>&1 && [[ -x "$cargo_bin_dir/$livediff_bin" ]]; then
  echo "✅ Livediff installed successfully."
  export PATH="$cargo_bin_dir:$PATH"
  if ! grep -q "$cargo_bin_dir" ~/.zshrc 2>/dev/null; then
    echo "💡 Adding Cargo bin dir to ~/.zshrc..."
    echo '' >> ~/.zshrc
    echo "# Rust/Cargo binaries (Livediff)" >> ~/.zshrc
    echo "export PATH=\"$cargo_bin_dir:\$PATH\"" >> ~/.zshrc
  fi
  echo "✅ Cargo bin dir added to PATH."
else
  echo "✅ Livediff installed successfully."
fi
echo

# === 5. Verify installation ===
echo "🧪 Verifying installation..."
echo

if command -v "$livediff_bin" >/dev/null 2>&1 || [[ -x "$cargo_bin_dir/$livediff_bin" ]]; then
  installed_version=$("$livediff_bin" --version 2>/dev/null || echo "unknown")
  echo "✅ Livediff: $livediff_bin (version: $installed_version)"
else
  echo "⚠️  Livediff not found in PATH. Open a new terminal and run: $livediff_bin --version"
  exit 1
fi

echo
echo "🎉 Livediff installation complete!"
echo
echo "💡 Next steps:"
echo "   • Watch current directory:   livediff ."
echo "   • Watch a subproject:        livediff ./src"
echo "   • Ignore noisy files:        livediff . --ignore \"target/\" --ignore \"*.tmp\""
echo "   • Show hidden files:         livediff --show-hidden"
echo "   • Disable ignore files:      livediff --no-ignore"
echo "   • Check all options:         livediff --help"
echo

# === 6. CLI use-cases ===
echo "🛠️  CLI use-cases:"
echo "   Terminal 1:   your-codemod/generator/formatter  (something editing files)"
echo "   Terminal 2:   livediff ./generated --ignore \"*.tmp\"   (watch it live)"
echo "   # Watch formatter output"
echo "   livediff ./src --ignore \"target/\""
echo "   # Watch migration output"
echo "   livediff ./migrations"
echo "   # Watch docs/config generation"
echo "   livediff ./docs"
echo "   # Whole repo, two ignores at once"
echo "   livediff . --ignore \"target/\" --ignore \"node_modules/\""
echo

# === 7. Notes & configuration ===
echo "📂 Configuration:"
echo "   • No config file needed - behavior is set via CLI flags"
echo "   • Respects .gitignore / .ignore files automatically (disable: --no-ignore)"
echo "   • Hidden files hidden by default (show: --show-hidden)"
echo "   • Ignores apply per flag: -i/--ignore <glob> (repeatable)"
echo "   • Rust toolchain is managed by Mise: mise ls rust / mise install rust@<ver>"
echo "   • Cargo installs to ~/.cargo/bin (should already be on PATH)"
echo "   • Updates: cargo install livediff --force"
echo "   • Pre-built binaries: https://github.com/SoCkEt7/Livediff/releases"
echo "   • Docs: https://github.com/SoCkEt7/Livediff"
echo
echo "▶️  Run: cd ~/my-project && livediff ."