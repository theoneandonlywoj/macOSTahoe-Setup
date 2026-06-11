#!/bin/zsh
# === tidewave.zsh ===
# Purpose: Install Tidewave Desktop and CLI for Elixir/Phoenix development on Apple chips/macOS Tahoe
# Shell: Zsh (default)
# Author: theoneandonlywoj

echo "🚀 Starting Tidewave installation for Elixir/Phoenix development on macOS Tahoe..."
echo

# === Configuration ===
install_desktop="yes"
install_cli="yes"
tidewave_app="/Applications/Tidewave.app"
tidewave_bin_dir="$HOME/.local/bin"
tidewave_cli="$tidewave_bin_dir/tidewave"
release_base="https://github.com/tidewave-ai/tidewave_app/releases/latest/download"

echo "📌 Desktop install?    $install_desktop"
echo "📌 CLI install?        $install_cli"
echo "🍎 Target platform:    Apple chips / Apple Silicon (Intel fallback included)"
echo "📂 App target:         $tidewave_app"
echo "📂 CLI target:         $tidewave_cli"
echo

# === 1. Detect architecture ===
machine_arch=$(uname -m)
case "$machine_arch" in
  arm64)
    desktop_asset="tidewave-app-aarch64.dmg"
    cli_asset="tidewave-cli-aarch64-apple-darwin"
    chip_note="Apple chips / Apple Silicon / M-series"
    ;;
  x86_64)
    desktop_asset="tidewave-app-x64.dmg"
    cli_asset="tidewave-cli-x86_64-apple-darwin"
    chip_note="Intel Mac fallback"
    ;;
  *)
    echo "❌ Unsupported macOS architecture: $machine_arch"
    exit 1
    ;;
esac

desktop_url="$release_base/$desktop_asset"
cli_url="$release_base/$cli_asset"

echo "✅ Detected architecture: $machine_arch ($chip_note)"
echo "📦 Desktop asset: $desktop_asset"
echo "📦 CLI asset:     $cli_asset"
echo

# === 2. Check required tools ===
if ! command -v curl >/dev/null 2>&1; then
  echo "❌ curl is required but was not found. Install Xcode Command Line Tools first."
  exit 1
fi

if [[ "$install_desktop" = "yes" ]] && ! command -v hdiutil >/dev/null 2>&1; then
  echo "❌ hdiutil is required to install the Tidewave Desktop app."
  exit 1
fi

echo "✅ Required macOS tools detected."
echo

# === 3. Install Tidewave Desktop ===
if [[ "$install_desktop" = "yes" ]]; then
  echo "===== Desktop App Installation ====="
  echo

  if [[ -d "$tidewave_app" ]]; then
    echo "✅ Tidewave Desktop is already installed at $tidewave_app"
  else
    tmp_dir=$(mktemp -d)
    dmg_path="$tmp_dir/$desktop_asset"

    echo "📥 Downloading Tidewave Desktop..."
    curl -fL "$desktop_url" -o "$dmg_path"
    if [[ $? -ne 0 ]]; then
      echo "❌ Failed to download Tidewave Desktop."
      rm -rf "$tmp_dir"
      exit 1
    fi

    echo "💿 Mounting Tidewave DMG..."
    mount_output=$(hdiutil attach "$dmg_path" -nobrowse 2>/dev/null)
    volume_path=$(print -r -- "$mount_output" | awk '/\/Volumes\// {print substr($0, index($0, "/Volumes/")); exit}')

    if [[ -z "$volume_path" || ! -d "$volume_path" ]]; then
      echo "❌ Failed to mount Tidewave DMG."
      rm -rf "$tmp_dir"
      exit 1
    fi

    app_source=$(find "$volume_path" -maxdepth 1 -name "*.app" -type d | head -n 1)
    if [[ -z "$app_source" ]]; then
      echo "❌ Could not find Tidewave.app in the mounted DMG."
      hdiutil detach "$volume_path" >/dev/null 2>&1
      rm -rf "$tmp_dir"
      exit 1
    fi

    echo "📦 Copying Tidewave Desktop to /Applications..."
    cp -R "$app_source" "/Applications/"
    copy_status=$?

    echo "💿 Unmounting Tidewave DMG..."
    hdiutil detach "$volume_path" >/dev/null 2>&1
    rm -rf "$tmp_dir"

    if [[ $copy_status -ne 0 ]]; then
      echo "❌ Failed to copy Tidewave Desktop to /Applications."
      exit 1
    fi

    echo "✅ Tidewave Desktop installed at $tidewave_app"
  fi
  echo
fi

# === 4. Install Tidewave CLI ===
if [[ "$install_cli" = "yes" ]]; then
  echo "===== CLI Installation ====="
  echo

  if command -v tidewave >/dev/null 2>&1; then
    echo "✅ Tidewave CLI is already installed: $(tidewave --version 2>/dev/null || echo 'version unknown')"
  elif [[ -x "$tidewave_cli" ]]; then
    echo "✅ Tidewave CLI is already installed at $tidewave_cli"
  else
    if [[ ! -d "$tidewave_bin_dir" ]]; then
      echo "📂 Creating CLI bin directory: $tidewave_bin_dir"
      mkdir -p "$tidewave_bin_dir"
      if [[ $? -ne 0 ]]; then
        echo "❌ Failed to create $tidewave_bin_dir"
        exit 1
      fi
    fi

    echo "📥 Downloading Tidewave CLI..."
    curl -fL "$cli_url" -o "$tidewave_cli"
    if [[ $? -ne 0 ]]; then
      echo "❌ Failed to download Tidewave CLI."
      exit 1
    fi

    chmod +x "$tidewave_cli"
    if [[ $? -ne 0 ]]; then
      echo "❌ Failed to make Tidewave CLI executable."
      exit 1
    fi

    echo "✅ Tidewave CLI installed at $tidewave_cli"
  fi
  echo
fi

# Make the CLI resolvable for this script after installing to ~/.local/bin.
if [[ ":$PATH:" != *":$tidewave_bin_dir:"* ]]; then
  export PATH="$tidewave_bin_dir:$PATH"
fi

# === 5. Verify installation ===
echo "🧪 Verifying Tidewave installation..."
echo

desktop_ok=false
cli_ok=false

if [[ -d "$tidewave_app" ]]; then
  echo "✅ Tidewave Desktop: installed at $tidewave_app"
  desktop_ok=true
else
  echo "⚠️  Tidewave Desktop not found at $tidewave_app"
fi

if command -v tidewave >/dev/null 2>&1; then
  echo "✅ Tidewave CLI: $(tidewave --version 2>/dev/null || echo 'installed')"
  cli_ok=true
elif [[ -x "$tidewave_cli" ]]; then
  echo "✅ Tidewave CLI: installed at $tidewave_cli"
  cli_ok=true
else
  echo "⚠️  Tidewave CLI not found."
fi

echo
if [[ "$desktop_ok" = true || "$cli_ok" = true ]]; then
  echo "🎉 Tidewave installation complete!"
else
  echo "❌ Tidewave installation failed. Please check the error logs above."
  exit 1
fi

# === 6. Phoenix setup guide ===
echo
echo "💡 Phoenix project setup guide:"
echo
echo "   1. Open your Phoenix project's mix.exs."
echo "   2. Add Tidewave to deps/0:"
echo
echo "        def deps do"
echo "          ["
echo "            {:tidewave, \"~> 0.5\", only: :dev},"
echo "            {:phoenix, ...}"
echo "          ]"
echo "        end"
echo
echo "   3. Fetch dependencies:"
echo "        mix deps.get"
echo
echo "   4. Open lib/my_app_web/endpoint.ex."
echo "   5. Add Tidewave above the 'if code_reloading? do' block:"
echo
echo "        if Mix.env() == :dev do"
echo "          plug Tidewave"
echo "        end"
echo
echo "        if code_reloading? do"
echo "          ..."
echo "        end"
echo
echo "   6. Optionally enable LiveView debug config in config/dev.exs."
echo "      Phoenix 1.8+ enables these by default, but older apps may need:"
echo
echo "        config :phoenix_live_view,"
echo "          debug_heex_annotations: true,"
echo "          debug_attributes: true"
echo
echo "   7. Start Phoenix:"
echo "        mix phx.server"
echo
echo "   8. Launch Tidewave and connect it to your app URL, usually:"
echo "        http://localhost:4000"
echo

# === 7. Phoenix umbrella setup guide ===
echo "💡 Phoenix umbrella project setup guide:"
echo
echo "   1. Find the umbrella child app that defines your Phoenix endpoint."
echo "      This is typically apps/my_app_web."
echo
echo "   2. Open that child app's mix.exs, for example:"
echo "        apps/my_app_web/mix.exs"
echo
echo "   3. Add Tidewave to that web app's deps/0:"
echo
echo "        def deps do"
echo "          ["
echo "            {:tidewave, \"~> 0.5\", only: :dev},"
echo "            {:phoenix, ...}"
echo "          ]"
echo "        end"
echo
echo "   4. From the umbrella root, fetch dependencies:"
echo "        mix deps.get"
echo
echo "   5. Open the endpoint in the web child app, for example:"
echo "        apps/my_app_web/lib/my_app_web/endpoint.ex"
echo
echo "   6. Add Tidewave above the 'if code_reloading? do' block:"
echo
echo "        if Mix.env() == :dev do"
echo "          plug Tidewave"
echo "        end"
echo
echo "        if code_reloading? do"
echo "          ..."
echo "        end"
echo
echo "   7. Optionally enable LiveView debug config in the dev config loaded by the umbrella."
echo "      This is usually config/dev.exs at the umbrella root."
echo "      Phoenix 1.8+ enables these by default, but older apps may need:"
echo
echo "        config :phoenix_live_view,"
echo "          debug_heex_annotations: true,"
echo "          debug_attributes: true"
echo
echo "   8. Start the umbrella Phoenix server from the umbrella root:"
echo "        mix phx.server"
echo
echo "   9. Launch Tidewave and connect it to your app URL, usually:"
echo "        http://localhost:4000"
echo
echo "📚 Docs: https://hexdocs.pm/tidewave/installation.html"
echo "📚 Phoenix integration: https://github.com/tidewave-ai/tidewave_phoenix"
echo
echo "✨ Happy Tidewaving!"
