#!/bin/zsh
# === yt_dlp.zsh ===
# Purpose: Install yt-dlp (YouTube downloader) on macOS Tahoe
# Shell: Zsh (default)
# Author: theoneandonlywoj

echo "🚀 Starting yt-dlp installation on macOS Tahoe..."
echo

# === 1. Check Homebrew installation ===
if ! command -v brew >/dev/null 2>&1; then
  echo "❌ Homebrew is not installed. Please run brew.zsh first."
  exit 1
fi
echo "✅ Homebrew detected."

# === 2. Install yt-dlp ===
echo
echo "📥 Installing yt-dlp via Homebrew..."
if command -v yt-dlp >/dev/null 2>&1; then
  echo "✅ yt-dlp is already installed: $(yt-dlp --version)"
else
  brew install yt-dlp
  if [[ $? -ne 0 ]]; then
    echo "❌ Failed to install yt-dlp"
    exit 1
  fi
  echo "✅ yt-dlp installed."
fi

# === 3. Verify installation ===
echo
echo "🧪 Verifying installation..."

yt_dlp_path=$(which yt-dlp 2>/dev/null)
if [[ -z "$yt_dlp_path" ]]; then
  echo "❌ yt-dlp not found in PATH."
  exit 1
fi
yt_dlp_v=$(yt-dlp --version 2>/dev/null)
if [[ -z "$yt_dlp_v" ]]; then
  echo "❌ Failed to retrieve yt-dlp version."
  exit 1
fi
echo "📌 yt-dlp: $yt_dlp_path"
echo "📌 Version: $yt_dlp_v"

echo
echo "✅ yt-dlp installed successfully!"

# === 4. Wrap-up ===
echo
echo "💡 Usage:"
echo "   • Download video:           yt-dlp <URL>"
echo "   • Download audio (mp3):     yt-dlp -x --audio-format mp3 <URL>"
echo "   • Download playlist:        yt-dlp <playlist-URL>"
echo "   • Update yt-dlp:            brew upgrade yt-dlp"
echo
echo "🎉 Installation finished successfully!"
