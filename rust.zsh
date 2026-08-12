#!/bin/zsh
# === rust.zsh ===
# Purpose: Install Rust using Mise on macOS Tahoe
# Shell: Zsh (default)
# Author: theoneandonlywoj

echo "🦀 Starting Rust installation via Mise on macOS Tahoe..."
echo

# === 0. Default version (used if .tool-versions / mise.toml is not present) ===
DEFAULT_RUST="stable"

# === 1. Determine version ===
RUST_VER=""
if [[ -f ".tool-versions" ]]; then
  RUST_VER=$(grep "^rust " .tool-versions | awk '{print $2}')
fi
if [[ -z "$RUST_VER" ]] && [[ -f "mise.toml" ]]; then
  RUST_VER=$(grep -E "^rust\s*=" mise.toml | sed -E 's/^rust\s*=\s*"([^"]+)".*/\1/')
fi
if [[ -z "$RUST_VER" ]]; then
  echo "ℹ️  No rust version found in .tool-versions or mise.toml. Using default: $DEFAULT_RUST"
  RUST_VER="$DEFAULT_RUST"
fi

echo "📌 Rust version to install: $RUST_VER"
echo

# === 2. Check Mise installation ===
if ! command -v mise >/dev/null 2>&1; then
  echo "❌ Mise is not installed. Please run ./mise.zsh first."
  exit 1
fi
echo "✅ Mise detected."

# === 3. Install Rust ===
echo
echo "📥 Installing Rust $RUST_VER via Mise..."
mise install rust@"$RUST_VER"
if [[ $? -ne 0 ]]; then
  echo "❌ Failed to install Rust $RUST_VER"
  exit 1
fi
mise use -g rust@"$RUST_VER"
echo "✅ Rust $RUST_VER installed and activated globally."

# === 4. Verify installation ===
echo
echo "🧪 Verifying installation..."

rustc_v=$(mise exec -- rustc --version 2>/dev/null)
if [[ -z "$rustc_v" ]]; then
  echo "❌ Failed to detect rustc. Please check your installation."
  exit 1
fi

cargo_v=$(mise exec -- cargo --version 2>/dev/null)
if [[ -z "$cargo_v" ]]; then
  echo "❌ Failed to detect cargo. Please check your installation."
  exit 1
fi

echo "📌 $rustc_v"
echo "📌 $cargo_v"

# === 5. Wrap-up ===
echo
echo "💡 Next steps:"
echo "   • Use Rust: rustc"
echo "   • Use Cargo: cargo"
echo "   • Manage versions with: mise install/use <tool>@<version>"
echo "   • Note: cargo installs binaries to ~/.cargo/bin"
echo
echo "🎉 Installation finished successfully!"