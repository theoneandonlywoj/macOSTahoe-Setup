#!/bin/zsh
# === elixir_and_erlang.zsh ===
# Purpose: Install Erlang and Elixir using Mise on macOS Tahoe
# Shell: Zsh (default)
# Author: theoneandonlywoj

echo "🚀 Starting Erlang + Elixir installation via Mise on macOS Tahoe..."
echo

# === 0. Default versions (used if .tool-versions is not present) ===
DEFAULT_ERLANG="28"
DEFAULT_ELIXIR="1.19.3-otp-28"

# === 1. Determine versions ===
if [[ -f ".tool-versions" ]]; then
  echo "📂 Found .tool-versions file. Reading versions..."
  ERLANG_VER=$(grep "^erlang " .tool-versions | awk '{print $2}')
  ELIXIR_VER=$(grep "^elixir " .tool-versions | awk '{print $2}')
  if [[ -z "$ERLANG_VER" ]]; then
    echo "⚠️  Erlang version not found in .tool-versions. Using default: $DEFAULT_ERLANG"
    ERLANG_VER="$DEFAULT_ERLANG"
  fi
  if [[ -z "$ELIXIR_VER" ]]; then
    echo "⚠️  Elixir version not found in .tool-versions. Using default: $DEFAULT_ELIXIR"
    ELIXIR_VER="$DEFAULT_ELIXIR"
  fi
else
  echo "ℹ️ .tool-versions not found. Using default versions."
  ERLANG_VER="$DEFAULT_ERLANG"
  ELIXIR_VER="$DEFAULT_ELIXIR"
fi

echo "📌 Erlang version to install: $ERLANG_VER"
echo "📌 Elixir version to install: $ELIXIR_VER"
echo

# === 2. Check Mise installation ===
if ! command -v mise >/dev/null 2>&1; then
  echo "❌ Mise is not installed. Please run install_mise.zsh first."
  exit 1
fi
echo "✅ Mise detected."

# === 3. Install Erlang ===
echo
echo "📥 Installing Erlang $ERLANG_VER via Mise..."
mise install erlang@"$ERLANG_VER"
if [[ $? -ne 0 ]]; then
  echo "❌ Failed to install Erlang $ERLANG_VER"
  exit 1
fi
mise use -g erlang@"$ERLANG_VER"
echo "✅ Erlang $ERLANG_VER installed and activated globally."

# === 4. Install Elixir ===
echo
echo "📥 Installing Elixir $ELIXIR_VER via Mise..."
mise install elixir@"$ELIXIR_VER"
if [[ $? -ne 0 ]]; then
  echo "❌ Failed to install Elixir $ELIXIR_VER"
  exit 1
fi
mise use -g elixir@"$ELIXIR_VER"
echo "✅ Elixir $ELIXIR_VER installed and activated globally."

# === 5. Verify installations ===
echo
echo "🧪 Verifying installations..."

# Verify Erlang version using mise exec to ensure proper environment
erlang_v=$(mise exec -- erl -eval 'io:format("~s~n", [erlang:system_info(otp_release)]), halt().' -noshell 2>/dev/null)
if [[ -z "$erlang_v" ]]; then
  echo "❌ Failed to retrieve Erlang version. The 'erl' command may have failed to run."
  exit 1
fi

# Verify Elixir version using mise exec to ensure proper environment
elixir_v=$(mise exec -- elixir -v 2>/dev/null | grep "Elixir" | awk '{print $2}')
if [[ -z "$elixir_v" ]]; then
  echo "❌ Failed to detect Elixir version. Please check your installation."
  exit 1
fi

echo "📌 Erlang version: $erlang_v"
echo "📌 Elixir version: $elixir_v"

# Check if versions match (allowing for minor differences in format)
erlang_major=$(echo "$erlang_v" | cut -d. -f1)
erlang_expected_major=$(echo "$ERLANG_VER" | cut -d. -f1)
elixir_base=$(echo "$elixir_v" | cut -d- -f1)
elixir_expected_base=$(echo "$ELIXIR_VER" | cut -d- -f1)

if [[ "$erlang_major" = "$erlang_expected_major" && "$elixir_base" = "$elixir_expected_base" ]]; then
  echo "✅ Erlang + Elixir setup complete!"
else
  echo "⚠️  Version mismatch detected. Check Mise installation."
  echo "   Expected Erlang: $ERLANG_VER (got: $erlang_v)"
  echo "   Expected Elixir: $ELIXIR_VER (got: $elixir_v)"
fi

# === 6. Wrap-up ===
echo
echo "💡 Next steps:"
echo "   • Use Erlang: erl"
echo "   • Use Elixir: iex"
echo "   • Manage versions with: mise install/use <tool>@<version>"
echo
echo "🎉 Installation finished successfully!"

