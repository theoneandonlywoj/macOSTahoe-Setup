#!/bin/zsh
# === observer_cli.zsh ===
# Purpose: Install observer_cli (terminal BEAM observer) via Mise-managed Elixir
# Shell: Zsh (default)
# Author: theoneandonlywoj

echo "📊 Starting observer_cli installation via Mise-managed Elixir..."
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

# === 2. Install observer_cli mix archive ===
echo
echo "📥 Installing observer_cli mix archive..."
if ! mise exec -- mix archive.install hex observer_cli --force; then
  echo "❌ Failed to install observer_cli archive."
  exit 1
fi
echo "✅ observer_cli archive installed."

# === 3. Verify installation ===
echo
echo "🧪 Verifying installation..."

if ! mise exec -- mix archive 2>/dev/null | grep -qi "observer_cli"; then
  echo "❌ observer_cli not found in mix archive list."
  exit 1
fi
echo "✅ observer_cli present in mix archive list."

# === 4. Wrap-up ===
echo
echo "✅ observer_cli installed successfully!"
echo
echo "💡 Usage (inside an IEx/Phoenix/Nerves node session):"
echo "   • Top processes:           :observer_cli"
echo "   • System + memory:         :observer_cli.system"
echo "   • Process detail:          :observer_cli.process <pid>"
echo "   • ETS tables:              :observer_cli.ets"
echo "   • Applications:            :observer_cli.applications"
echo
echo "💡 For remote Nerves nodes:  iex --remsh node@host  then  :observer_cli"
echo
echo "🎉 Installation finished successfully!"
