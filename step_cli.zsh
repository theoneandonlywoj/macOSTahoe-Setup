#!/bin/zsh
# === step_cli.zsh ===
# Purpose: Install step-cli (Smallstep) for local CA / mTLS certs (BEAM distribution, clustering)
# Shell: Zsh (default)
# Author: theoneandonlywoj

echo "🔐 Starting step-cli (Smallstep) installation on macOS Tahoe..."
echo

# === 1. Check Homebrew installation ===
if ! command -v brew >/dev/null 2>&1; then
  echo "❌ Homebrew is not installed. Please run brew.zsh first."
  exit 1
fi
echo "✅ Homebrew detected."

# === 2. Install step ===
echo
echo "📥 Installing step via Homebrew..."
if command -v step >/dev/null 2>&1; then
  echo "ℹ️  step is already installed. Upgrading to latest..."
  brew upgrade step 2>/dev/null || echo "⚠️  Upgrade skipped (already up-to-date)."
else
  brew install step
  if [[ $? -ne 0 ]]; then
    echo "❌ Failed to install step"
    exit 1
  fi
fi
echo "✅ step installed."

# === 3. Verify installation ===
echo
echo "🧪 Verifying installation..."

step_path=$(which step 2>/dev/null)
if [[ -z "$step_path" ]]; then
  echo "❌ step not found in PATH."
  exit 1
fi
echo "📌 step: $step_path"

step_version=$(step version 2>/dev/null | head -1)
if [[ -n "$step_version" ]]; then
  echo "📌 Version: $step_version"
fi

# === 4. Wrap-up ===
echo
echo "✅ step installed successfully!"
echo
echo "💡 Usage (securing BEAM distribution / clustering between nodes):"
echo "   • Boot a local CA:           step ca init --name MyOrg --dns ca.local --address :443"
echo "   • Issue a leaf cert:         step certificate create node1.local node1.crt node1.key \\"
echo "                                  --ca root_ca.crt --ca-key root_ca_key --not-after 24h"
echo "   • mTLS between BEAM nodes:   erl -proto_dist inet_tls \\"
echo "                                  -ssl_dist_opt client_crt node1.crt -ssl_dist_opt server_crt node1.crt"
echo "   • Get a cert via ACME:       step ca certificate node1.local node1.crt node1.key"
echo "   • Inspect a cert:            step certificate inspect node1.crt"
echo
echo "🎉 Installation finished successfully!"
