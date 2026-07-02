#!/bin/zsh
# === livebook.zsh ===
# Purpose: Install Livebook (interactive Elixir notebooks) as an escript via
#          Mise-managed Elixir. The escript lands in the version-specific
#          .mix/escripts/ directory which Mise already puts on PATH, so
#          `mise exec -- livebook` resolves correctly.
# Shell: Zsh (default)
# Author: theoneandonlywoj

echo "📓 Starting Livebook installation via Mise-managed Elixir..."
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

# === 2. Remove any stale archive install (livebook is an escript, not an archive) ===
echo
echo "🧹 Checking for stale Livebook archive install..."
if mise exec -- mix archive 2>/dev/null | grep -qi '^* livebook'; then
  echo "ℹ️  Found stale livebook archive. Removing (livebook is installed as an escript)..."
  yes | mise exec -- mix archive.uninstall livebook 2>/dev/null
  if mise exec -- mix archive 2>/dev/null | grep -qi '^* livebook'; then
    echo "⚠️  Failed to remove stale archive. Continuing anyway."
  else
    echo "✅ Stale archive removed."
  fi
else
  echo "✅ No stale livebook archive found."
fi

# === 3. Ensure Hex + Rebar are available (required to build the escript) ===
echo
echo "📥 Ensuring Hex and Rebar3 are available..."
if ! mise exec -- mix local.hex --force >/dev/null 2>&1; then
  echo "⚠️  mix local.hex failed. Continuing..."
fi
if ! mise exec -- mix local.rebar --force >/dev/null 2>&1; then
  echo "⚠️  mix local.rebar failed. Continuing..."
fi
echo "✅ Hex and Rebar3 ready."

# === 4. Install Livebook as an escript ===
echo
echo "📥 Installing Livebook escript..."
if ! mise exec -- mix escript.install hex livebook --force; then
  echo "❌ Failed to install Livebook escript."
  exit 1
fi
echo "✅ Livebook escript installed."

# === 5. Verify installation ===
echo
echo "🧪 Verifying installation..."

escripts_dir=$(mise exec -- sh -c 'echo "${MIX_HOME:-$HOME/.mix}/escripts"')
if [[ -z "$escripts_dir" ]]; then
  escripts_dir="$HOME/.mix/escripts"
fi

livebook_path=$(mise exec -- command -v livebook 2>/dev/null)
if [[ -z "$livebook_path" ]]; then
  echo "❌ livebook not found on Mise PATH."
  echo "   Expected escript at: $escripts_dir/livebook"
  echo "   Run 'mise exec -- mix escript' to list installed escripts."
  exit 1
fi
echo "📌 livebook: $livebook_path"
echo "📌 Escripts dir: $escripts_dir  (already on Mise PATH)"

# Confirm it actually runs
if mise exec -- livebook --version >/dev/null 2>&1; then
  echo "✅ livebook runs under Mise."
else
  echo "⚠️  livebook binary present but 'mise exec -- livebook --version' failed."
fi

# === 6. Wrap-up ===
echo
echo "✅ Livebook installed successfully!"
echo
echo "💡 Usage:"
echo "   • Start a notebook server:  mise exec -- livebook server"
echo "   • Open in browser:          http://localhost:8080"
echo "   • Show all options:         mise exec -- livebook server --help"
echo "   • Set a password:           LIVEBOOK_PASSWORD=... mise exec -- livebook server"
echo "   • Bind to all interfaces:   mise exec -- livebook server --ip 0.0.0.0"
echo
echo "💡 Connect a notebook to a Phoenix/Nerves node:"
echo "   In Livebook: Add runtime → 'Attached node' → node@host + cookie."
echo
echo "🎉 Installation finished successfully!"
