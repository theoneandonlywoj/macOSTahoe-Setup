#!/bin/zsh
# === credo.zsh ===
# Purpose: Install Credo (Elixir static-analysis linter) via Mise-managed Elixir
# Shell: Zsh (default)
# Author: theoneandonlywoj

echo "🔍 Starting Credo installation via Mise-managed Elixir..."
echo

# === 1. Verify Mise + Elixir are available ===
if ! command -v mise >/dev/null 2>&1; then
  echo "❌ Mise is not installed. Please run mise.zsh first."
  exit 1
fi
echo "✅ Mise detected."

if ! mise exec -- elixir -v >/dev/null 2>&1; then
  echo "❌ Elixir is not installed via Mise. Please run elixir_and_erlang.zsh first."
  exit 1
fi
echo "✅ Elixir detected via Mise: $(mise exec -- elixir -v 2>/dev/null | grep Elixir)"

if ! mise exec -- command -v mix >/dev/null 2>&1; then
  echo "❌ mix not found in Mise Elixir environment."
  exit 1
fi

# === 2. Install Credo mix archive ===
echo
echo "📥 Installing Credo mix archive..."
if ! mise exec -- mix archive.install hex credo --force; then
  echo "❌ Failed to install Credo archive."
  exit 1
fi
echo "✅ Credo archive installed."

# === 3. Verify installation ===
echo
echo "🧪 Verifying installation..."

if ! mise exec -- mix archive 2>/dev/null | grep -qi "credo"; then
  echo "❌ Credo not found in mix archive list."
  exit 1
fi
echo "✅ Credo present in mix archive list."

# === 4. Wrap-up ===
echo
echo "✅ Credo installed successfully!"
echo
echo "💡 Usage (inside a Phoenix/Elixir project):"
echo "   • Lint the project:           mise exec -- mix credo"
echo "   • Strict checks (warnings):   mise exec -- mix credo --strict"
echo "   • Suggest refactorings:       mise exec -- mix credo --suggest"
echo "   • JSON output for CI:         mise exec -- mix credo --format json"
echo
echo "💡 Note: for per-project pinning, add {:credo, \"~> 1.7\", only: :dev} to mix.exs."
echo
echo "🎉 Installation finished successfully!"
