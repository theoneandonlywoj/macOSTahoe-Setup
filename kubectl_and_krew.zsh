#!/bin/zsh
# === kubectl_and_krew.zsh ===
# Purpose: Install kubectl and krew (kubectl plugin manager) on macOS
# Shell: Zsh (default)
# Author: theoneandonlywoj

echo "🚀 Starting kubectl + krew installation on macOS..."
echo

# === 0. Basic sanity checks ===

# macOS check
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "❌ This script is intended for macOS only."
  exit 1
fi

# Check for Homebrew
if ! command -v brew >/dev/null 2>&1; then
  echo "❌ Homebrew is not installed."
  echo "   Please install Homebrew first from: https://brew.sh"
  exit 1
fi
echo "✅ Homebrew detected."

# === 1. Install kubectl via Homebrew ===
echo
echo "📥 Installing kubectl via Homebrew..."
if brew list kubectl >/dev/null 2>&1; then
  echo "ℹ️  kubectl is already installed. Upgrading to latest..."
  brew upgrade kubectl || {
    echo "⚠️  Failed to upgrade kubectl. Continuing with existing version."
  }
else
  brew install kubectl
  if [[ $? -ne 0 ]]; then
    echo "❌ Failed to install kubectl via Homebrew."
    exit 1
  fi
fi

if ! command -v kubectl >/dev/null 2>&1; then
  echo "❌ kubectl command not found even after installation."
  exit 1
fi
echo "✅ kubectl installed and available."

# === 2. Install krew (kubectl plugin manager) ===
echo
echo "📥 Installing krew (kubectl plugin manager)..."

tempdir="$(mktemp -d 2>/dev/null || mktemp -d -t krew_install)"
if [[ -z "$tempdir" ]]; then
  echo "❌ Failed to create temporary directory for krew installation."
  exit 1
fi

(
  set -e
  cd "$tempdir"

  OS="$(uname | tr '[:upper:]' '[:lower:]')"
  ARCH="$(uname -m | sed -e 's/x86_64/amd64/' \
                         -e 's/arm64/arm64/' \
                         -e 's/aarch64/arm64/' \
                         -e 's/arm.*/arm64/')"

  KREW="krew-${OS}_${ARCH}"
  echo "ℹ️  Detected OS: $OS"
  echo "ℹ️  Detected Arch: $ARCH"

  echo "🌐 Downloading krew binary..."
  curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz"

  echo "📦 Extracting krew..."
  tar zxvf "${KREW}.tar.gz" >/dev/null

  echo "⚙️  Running krew installer..."
  ./"${KREW}" install krew
)

if [[ $? -ne 0 ]]; then
  echo "❌ Failed to install krew."
  echo "   You can retry manually using the instructions at:"
  echo "   https://krew.sigs.k8s.io/docs/user-guide/setup/install/"
  exit 1
fi

echo "✅ krew installed."

# === 3. Verification ===
echo
echo "🧪 Verifying kubectl and krew..."

# Ensure PATH includes krew for this session
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

# Some kubectl builds print version info to stderr; capture both stdout and stderr
kubectl_version=$(kubectl version --client --short 2>&1)
if [[ $? -ne 0 ]]; then
  echo "❌ Failed to retrieve kubectl version (non-zero exit code)."
  echo "   Output was:"
  echo "   $kubectl_version"
  exit 1
fi
if [[ -z "$kubectl_version" ]]; then
  echo "❌ kubectl is installed but 'kubectl version --client --short' returned no output."
  exit 1
fi

krew_version=$(kubectl krew version 2>/dev/null | head -n 1)
if [[ -z "$krew_version" ]]; then
  echo "❌ Failed to verify krew. Ensure PATH includes \$HOME/.krew/bin."
  exit 1
fi

echo "📌 kubectl: $kubectl_version"
echo "📌 krew: $krew_version"
echo "✅ kubectl + krew setup complete!"

# === 4. Wrap-up ===
echo
echo "💡 Next steps:"
echo "   • Ensuring krew PATH is configured in ~/.zshrc..."

ZSHRC_PATH="$HOME/.zshrc"
KREW_PATH_LINE='export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"'

if [[ -f "$ZSHRC_PATH" ]]; then
  if grep -Fq "$KREW_PATH_LINE" "$ZSHRC_PATH"; then
    echo "     - PATH line for krew already present in ~/.zshrc"
  else
    {
      echo ""
      echo "# Added by kubectl_and_krew.zsh on $(date)"
      echo "$KREW_PATH_LINE"
    } >> "$ZSHRC_PATH"
    echo "     - Added krew PATH line to ~/.zshrc"
  fi
else
  {
    echo "# Created by kubectl_and_krew.zsh on $(date)"
    echo "$KREW_PATH_LINE"
  } >> "$ZSHRC_PATH"
  echo "     - Created ~/.zshrc and added krew PATH line"
fi

echo "   • To pick up changes now, run: source ~/.zshrc"
echo "   • List installed plugins: kubectl krew list"
echo "   • Discover new plugins:  kubectl krew search"
echo "   • Install a plugin:      kubectl krew install <plugin-name>"
echo
echo "🎉 Installation finished successfully!"


