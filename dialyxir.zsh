#!/bin/zsh
# === dialyxir.zsh ===
# Purpose: Install Dialyxir (Elixir type-checking via dialyzer) via Mise-managed Elixir
# Shell: Zsh (default)
# Author: theoneandonlywoj

echo "🧪 Starting Dialyxir installation via Mise-managed Elixir..."
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

# === 2. Install Dialyxir mix archive ===
echo
echo "📥 Installing Dialyxir mix archive..."
if ! mise exec -- mix archive.install hex dialyxir --force; then
  echo "❌ Failed to install Dialyxir archive."
  exit 1
fi
echo "✅ Dialyxir archive installed."

# === 3. Verify installation ===
echo
echo "🧪 Verifying installation..."

if ! mise exec -- mix archive 2>/dev/null | grep -qi "dialyxir"; then
  echo "❌ Dialyxir not found in mix archive list."
  exit 1
fi
echo "✅ Dialyxir present in mix archive list."

# === 4. Wrap-up ===
echo
echo "✅ Dialyxir installed successfully!"
echo
echo "💡 Usage (inside a Phoenix/Elixir project):"
echo "   • Build the PLT (first run, slow):    mise exec -- mix dialyzer --plt"
echo "   • Run type checks:                    mise exec -- mix dialyzer"
echo "   • Halt on warnings (for CI):          mise exec -- mix dialyzer --halt-on-Exit3"
echo
echo "💡 Note: for per-project pinning, add {:dialyxir, \"~> 1.4\", only: [:dev, :test]} to mix.exs."
echo
echo "🎉 Installation finished successfully!"
