#!/bin/zsh
# === podman.zsh ===
# Purpose: Install Podman (container engine) on macOS Tahoe with Zsh and a working Docker alias
# Shell: Zsh (default on macOS Tahoe)
# Author: theoneandonlywoj

echo "🚀 Starting Podman installation on macOS Tahoe..."
echo

# === Configuration ===
podman_bin="/opt/homebrew/bin/podman"
zshrc_path="$HOME/.zshrc"
alias_line="alias docker='podman'"

echo "📦 Target binary: $podman_bin"
echo "🧠 Shell: Zsh"
echo

# === 1. Install or update Podman ===
echo "📥 Installing Podman..."
if brew list podman &>/dev/null; then
  echo "ℹ️  Podman is already installed. Upgrading to latest version..."
  brew upgrade podman || echo "⚠️  Upgrade skipped (already up-to-date)."
else
  brew install podman
fi

# === 2. Verify installation ===
if command -v podman >/dev/null 2>&1; then
  echo "✅ Podman installed successfully!"
else
  echo "❌ Podman installation failed. Aborting."
  exit 1
fi

# === 3. Initialize and start Podman machine ===
echo
echo "🧰 Checking Podman machine status..."
if ! podman machine list | grep -q "podman-machine-default"; then
  echo "🆕 Creating Podman virtual machine (default)..."
  podman machine init
else
  echo "✅ Podman machine already exists."
fi

echo "▶️ Starting Podman machine..."
podman machine start
if [[ $? -ne 0 ]]; then
  echo "❌ Failed to start Podman machine."
  exit 1
fi

# === 4. Set DOCKER_HOST to Podman socket ===
echo
echo "🔌 Configuring DOCKER_HOST to use Podman socket..."
export DOCKER_HOST="unix://$(podman machine inspect --format '{{.ConnectionInfo.PodmanSocket.Path}}')"

# === 5. Add Docker alias to Zsh ===
echo
echo "🔗 Adding Docker alias to ~/.zshrc..."
if grep -Fxq "$alias_line" "$zshrc_path"; then
  echo "✅ Docker alias already exists in ~/.zshrc"
else
  echo "\n# Docker alias using Podman" >> "$zshrc_path"
  echo "$alias_line" >> "$zshrc_path"
  echo "✅ Docker alias added to ~/.zshrc"
fi

# Apply immediately
eval "$alias_line"

# === 6. Verify Podman functionality ===
echo
echo "🧪 Testing Podman setup..."
if podman info >/dev/null 2>&1; then
  podman_version=$(podman --version)
  echo "✅ Podman is running successfully!"
  echo "📘 Version: $podman_version"
else
  echo "⚠️  Podman installed but not responding properly. Try restarting the machine:"
  echo "   podman machine stop && podman machine start"
fi

# === 7. Verify Docker alias works ===
echo
echo "🧩 Testing docker alias..."
if docker ps >/dev/null 2>&1; then
  echo "✅ Docker alias works correctly — 'docker ps' maps to Podman!"
else
  echo "⚠️  Docker alias may not yet be active in new shells. Run: source ~/.zshrc"
fi

# === 8. Wrap-up ===
echo
echo "🎉 Podman installation complete!"
echo
echo "💡 Useful commands:"
echo "   • podman machine start          → Start Podman virtual machine"
echo "   • docker ps                     → (Alias) List running containers"
echo "   • docker run -it alpine sh      → (Alias) Run lightweight container"
echo "   • podman images                 → List container images"
echo "   • podman machine stop           → Stop Podman VM"
echo
echo "🐳 You can now use 'docker' commands — powered by Podman (just restart the terminal)!"

