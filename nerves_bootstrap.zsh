#!/bin/zsh
# === nerves_bootstrap.zsh ===
# Purpose: Install Nerves Bootstrap (mix archive for scaffolding Nerves projects)
#          via Mise-managed Elixir
# Shell: Zsh (default)
# Author: theoneandonlywoj

echo "🧩 Starting Nerves Bootstrap installation via Mise-managed Elixir..."
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

# === 2. Install nerves_bootstrap mix archive ===
echo
echo "📥 Installing nerves_bootstrap mix archive..."
if ! mise exec -- mix archive.install hex nerves_bootstrap --force; then
  echo "❌ Failed to install nerves_bootstrap archive."
  exit 1
fi
echo "✅ nerves_bootstrap archive installed."

# === 3. Verify installation ===
echo
echo "🧪 Verifying installation..."

if ! mise exec -- mix archive 2>/dev/null | grep -qi "nerves_bootstrap"; then
  echo "❌ nerves_bootstrap not found in mix archive list."
  exit 1
fi
echo "✅ nerves_bootstrap present in mix archive list."

# === 4. Wrap-up ===
echo
echo "✅ nerves_bootstrap installed successfully!"
echo
echo "💡 Usage:"
echo "   • Scaffold a Nerves project:"
echo "       mise exec -- mix nerves.new my_firmware"
echo "   • Common Nerves dependencies to add: nerves, nerves_pack, vintage_net"
echo
echo "💡 Prerequisites for actually building firmware:"
echo "   • Run fwup.zsh          (firmware flashing)"
echo "   • Run picocom.zsh       (serial console to target)"
echo "   • Run qemu.zsh          (emulate targets without hardware)"
echo
echo "🎉 Installation finished successfully!"
