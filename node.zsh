#!/bin/zsh
# === node.zsh ===
# Purpose: Install Node.js using Mise on macOS Tahoe
# Shell: Zsh (default)
# Author: theoneandonlywoj

echo "🚀 Starting Node.js installation via Mise on macOS Tahoe..."
echo

# === 0. Default version (used if .tool-versions is not present) ===
DEFAULT_NODE="26"

# === 1. Determine version ===
if [[ -f ".tool-versions" ]]; then
  echo "📂 Found .tool-versions file. Reading versions..."
  NODE_VER=$(grep "^nodejs " .tool-versions | awk '{print $2}')
  if [[ -z "$NODE_VER" ]]; then
    echo "⚠️  Node.js version not found in .tool-versions. Using default: $DEFAULT_NODE"
    NODE_VER="$DEFAULT_NODE"
  fi
else
  echo "ℹ️ .tool-versions not found. Using default version."
  NODE_VER="$DEFAULT_NODE"
fi

echo "📌 Node.js version to install: $NODE_VER"
echo

# === 2. Check Mise installation ===
if ! command -v mise >/dev/null 2>&1; then
  echo "❌ Mise is not installed. Please run install_mise.zsh first."
  exit 1
fi
echo "✅ Mise detected."

# === 3. Install Node.js ===
echo
echo "📥 Installing Node.js $NODE_VER via Mise..."
mise install nodejs@"$NODE_VER"
if [[ $? -ne 0 ]]; then
  echo "❌ Failed to install Node.js $NODE_VER"
  exit 1
fi
mise use -g nodejs@"$NODE_VER"
echo "✅ Node.js $NODE_VER installed and activated globally."

# === 4. Verify installation ===
echo
echo "🧪 Verifying installation..."

# Verify Node version using mise exec to ensure proper environment
node_v=$(mise exec -- node -v 2>/dev/null | sed 's/^v//')
if [[ -z "$node_v" ]]; then
  echo "❌ Failed to retrieve Node.js version. The 'node' command may have failed to run."
  exit 1
fi

# Verify npm version using mise exec to ensure proper environment
npm_v=$(mise exec -- npm -v 2>/dev/null)
if [[ -z "$npm_v" ]]; then
  echo "❌ Failed to detect npm version. Please check your installation."
  exit 1
fi

echo "📌 Node.js version: $node_v"
echo "📌 npm version: $npm_v"

# Check if version matches (allowing for minor differences in format)
node_major=$(echo "$node_v" | cut -d. -f1)
node_expected_major=$(echo "$NODE_VER" | cut -d. -f1)

if [[ "$node_major" = "$node_expected_major" ]]; then
  echo "✅ Node.js setup complete!"
else
  echo "⚠️  Version mismatch detected. Check Mise installation."
  echo "   Expected Node.js: $NODE_VER (got: $node_v)"
fi

# === 5. Wrap-up ===
echo
echo "💡 Next steps:"
echo "   • Use Node.js: node"
echo "   • Use npm: npm"
echo "   • Manage versions with: mise install/use <tool>@<version>"
echo
echo "🎉 Installation finished successfully!"
