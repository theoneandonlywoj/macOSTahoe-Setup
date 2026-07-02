#!/bin/zsh
# === act.zsh ===
# Purpose: Install act (run GitHub Actions workflows locally) for validating
#          Buildroot + Elixir release pipelines before pushing. Also ensures a
#          minimal .github/workflows/smoke-test.yml exists so `act` always has
#          something to execute out of the box.
# Shell: Zsh (default)
# Author: theoneandonlywoj

echo "🎬 Starting act installation on macOS Tahoe..."
echo

# === 1. Check Homebrew installation ===
if ! command -v brew >/dev/null 2>&1; then
  echo "❌ Homebrew is not installed. Please run brew.zsh first."
  exit 1
fi
echo "✅ Homebrew detected."

# === 2. Install act ===
echo
echo "📥 Installing act via Homebrew..."
if command -v act >/dev/null 2>&1; then
  echo "ℹ️  act is already installed. Upgrading to latest..."
  brew upgrade act 2>/dev/null || echo "⚠️  Upgrade skipped (already up-to-date)."
else
  brew install act
  if [[ $? -ne 0 ]]; then
    echo "❌ Failed to install act"
    exit 1
  fi
fi
echo "✅ act installed."

# === 3. Verify installation ===
echo
echo "🧪 Verifying installation..."

act_path=$(which act 2>/dev/null)
if [[ -z "$act_path" ]]; then
  echo "❌ act not found in PATH."
  exit 1
fi
echo "📌 act: $act_path"

act_version=$(act --version 2>/dev/null | head -1)
if [[ -n "$act_version" ]]; then
  echo "📌 Version: $act_version"
fi

# === 4. Ensure a container runtime is available (Docker or Podman) ===
echo
echo "🐳 Checking for a container runtime..."
if command -v docker >/dev/null 2>&1; then
  echo "✅ Docker detected."
  if docker info >/dev/null 2>&1; then
    echo "✅ Docker daemon is running."
  else
    echo "⚠️  Docker is installed but the daemon is not running. Start Docker Desktop."
  fi
elif command -v podman >/dev/null 2>&1; then
  echo "✅ Podman detected (Apple Silicon friendly)."
  echo "ℹ️  Point act at the Podman socket with:"
  echo "      export DOCKER_HOST=unix://$HOME/.local/share/containers/podman/machine/podman.sock"
else
  echo "❌ Neither Docker nor Podman found. Run docker_compose.zsh or podman.zsh first."
  exit 1
fi

# === 5. Seed a minimal smoke-test workflow so `act` works out of the box ===
echo
echo "📝 Ensuring .github/workflows/smoke-test.yml exists..."
workflows_dir=".github/workflows"
if [[ ! -d "$workflows_dir" ]]; then
  mkdir -p "$workflows_dir"
fi

smoke_file="$workflows_dir/smoke-test.yml"
if [[ -f "$smoke_file" ]]; then
  echo "✅ smoke-test.yml already present."
else
  cat >"$smoke_file" <<'YAML'
name: smoke-test

on:
  push:
    branches: ["**"]
  pull_request:
    branches: ["**"]
  workflow_dispatch:

jobs:
  smoke:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: List setup scripts
        run: ls -1 *.zsh | sort

      - name: Shellcheck placeholder
        run: |
          echo "Skipping shellcheck in smoke job (install via brew if needed)."
YAML
  echo "✅ Created $smoke_file"
fi

# === 6. List available jobs to confirm act can discover the workflow ===
echo
echo "🧪 Listing act jobs..."
act -l 2>&1 | sed 's/^/   /' || echo "⚠️  'act -l' failed (is the container daemon running?)"

# === 7. Wrap-up ===
echo
echo "✅ act installed successfully!"
echo
echo "💡 Usage (validating CI before push):"
echo "   • Run all workflows:           act"
echo "   • List available jobs:         act -l"
echo "   • Run a specific job:          act -j smoke"
echo "   • Dry run (no execution):      act -n"
echo "   • Apple Silicon (recommended): act --container-architecture linux/amd64"
echo "   • Run smoke workflow on Apple Silicon:"
echo "       act --container-architecture linux/amd64 -W .github/workflows/smoke-test.yml"
echo "   • Use a smaller runner image:  act -P ubuntu-latest=catthehacker/ubuntu:act-latest"
echo "   • Pass secrets:                act --secret-file .secrets"
echo "   • Pair with podman.zsh on Apple Silicon:"
echo "       export DOCKER_HOST=unix://$HOME/.local/share/containers/podman/machine/podman.sock"
echo
echo "🎉 Installation finished successfully!"
