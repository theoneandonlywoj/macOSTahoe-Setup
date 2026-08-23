#!/bin/zsh
# === yt_dlp.zsh ===
# Purpose: Install yt-dlp (YouTube downloader) + ffmpeg (muxing companion) on macOS Tahoe
# Shell: Zsh (default on macOS Tahoe)
# Author: theoneandonlywoj

echo "🚀 Starting yt-dlp installation on macOS Tahoe..."
echo

# === Configuration ===
yt_dlp_bin="yt-dlp"
yt_dlp_path="$(brew --prefix 2>/dev/null)/bin/yt-dlp"
ffmpeg_bin="ffmpeg"
ffmpeg_path="$(brew --prefix 2>/dev/null)/bin/ffmpeg"
zshrc_path="$HOME/.zshrc"

echo "🔗 Binary:             $yt_dlp_bin"
echo "📂 Default location:   $yt_dlp_path"
echo "🔗 Companion binary:   $ffmpeg_bin"
echo "📂 Companion location: $ffmpeg_path"
echo

# === 1. Check Homebrew ===
if ! command -v brew >/dev/null 2>&1; then
  echo "❌ Homebrew is not installed. Please run brew.zsh first."
  exit 1
fi
echo "✅ Homebrew detected."
echo

# === 2. Install yt-to-mp4 shell wrapper (always ensured, idempotent) ===
echo "🔗 Ensuring yt-to-mp4 shell function in ~/.zshrc..."
touch "$zshrc_path"

# Strip any prior managed block (sentinel) and legacy non-sentinel block
awk '
  /^# >>> yt-to-mp4 \(yt_dlp\.zsh\) >>>/ {insent=1; next}
  /^# <<< yt-to-mp4 \(yt_dlp\.zsh\) <<</ {insent=0; next}
  insent {next}
  /^# yt-to-mp4:/ {inleg=1; next}
  inleg && /^}$/ {inleg=0; next}
  inleg {next}
  {print}
' "$zshrc_path" > "$zshrc_path.tmp" && mv "$zshrc_path.tmp" "$zshrc_path"

cat <<'EOF' >> "$zshrc_path"

# >>> yt-to-mp4 (yt_dlp.zsh) >>>
# Download best audio+video merged into a single mp4.
# Usage: yt-to-mp4 <URL> | yt-to-mp4 --link <URL>  (noglob: URLs may be unquoted)
_yt_to_mp4_impl() {
  local link=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --link)
        if [[ -z "${2:-}" ]]; then
          echo "❌ --link requires a value. Usage: yt-to-mp4 --link <URL>" >&2
          return 1
        fi
        link="$2"; shift 2 ;;
      -h|--help)
        echo "Usage: yt-to-mp4 <URL> | yt-to-mp4 --link <URL>"
        echo "Downloads best video+audio and merges them into a single .mp4."
        return 0 ;;
      *)
        link="$1"; shift ;;
    esac
  done
  if [[ -z "$link" ]]; then
    echo "❌ No link provided. Usage: yt-to-mp4 <URL> | yt-to-mp4 --link <URL>" >&2
    return 1
  fi
  yt-dlp -f "bv*+ba/b" --merge-output-format mp4 "$link"
}
alias yt-to-mp4='noglob _yt_to_mp4_impl'
# <<< yt-to-mp4 (yt_dlp.zsh) <<<
EOF
echo "✅ yt-to-mp4 shell function installed in ~/.zshrc"

# Apply for this session
source "$zshrc_path" 2>/dev/null

echo
echo "🧩 Testing yt-to-mp4 wrapper..."
if typeset -f _yt_to_mp4_impl >/dev/null 2>&1 && [[ -n "${aliases[yt-to-mp4]:-}" ]]; then
  echo "✅ yt-to-mp4 is available in this session"
  echo "   Try: yt-to-mp4 <URL>  or  yt-to-mp4 --link <URL>  (URLs may be unquoted)"
else
  echo "⚠️  yt-to-mp4 not active yet. Run: source ~/.zshrc"
fi
echo

# === 3. Check if both yt-dlp and ffmpeg are already installed ===
yt_dlp_installed=false
ffmpeg_installed=false
command -v "$yt_dlp_bin" >/dev/null 2>&1 || [[ -x "$yt_dlp_path" ]] && yt_dlp_installed=true
command -v "$ffmpeg_bin" >/dev/null 2>&1 || [[ -x "$ffmpeg_path" ]] && ffmpeg_installed=true

if [[ "$yt_dlp_installed" = true && "$ffmpeg_installed" = true ]]; then
  if command -v "$yt_dlp_bin" >/dev/null 2>&1; then
    current_version=$("$yt_dlp_bin" --version 2>/dev/null || echo "unknown")
    echo "✅ yt-dlp is already installed: $yt_dlp_bin (version: $current_version)"
  else
    current_version=$("$yt_dlp_path" --version 2>/dev/null || echo "unknown")
    echo "✅ yt-dlp is already installed at $yt_dlp_path (version: $current_version)"
  fi
  if command -v "$ffmpeg_bin" >/dev/null 2>&1; then
    ffmpeg_version=$("$ffmpeg_bin" -version 2>/dev/null | head -1 || echo "unknown")
    echo "✅ ffmpeg is already installed: $ffmpeg_bin ($ffmpeg_version)"
  else
    ffmpeg_version=$("$ffmpeg_path" -version 2>/dev/null | head -1 || echo "unknown")
    echo "✅ ffmpeg is already installed at $ffmpeg_path ($ffmpeg_version)"
  fi
  echo
  echo "💡 To update, run: brew upgrade yt-dlp ffmpeg"
  echo "🎉 Nothing to do!"
  exit 0
fi

# === 4. Install yt-dlp if missing ===
if [[ "$yt_dlp_installed" = false ]]; then
  echo "📥 Installing yt-dlp via Homebrew..."
  brew install yt-dlp
  install_status=$?

  yt_dlp_found=false
  command -v "$yt_dlp_bin" >/dev/null 2>&1 || [[ -x "$yt_dlp_path" ]] && yt_dlp_found=true

  if [[ $install_status -ne 0 ]] && [[ "$yt_dlp_found" = false ]]; then
    echo "❌ yt-dlp install failed (Homebrew)."
    echo "⚠️  Try running manually: brew install yt-dlp"
    exit 1
  fi
  if command -v "$yt_dlp_bin" >/dev/null 2>&1 || [[ -x "$yt_dlp_path" ]]; then
    echo "✅ yt-dlp installed successfully."
  else
    echo "⚠️  yt-dlp not found in PATH or at $yt_dlp_path."
    echo "   You may need to restart your terminal."
  fi
fi

# === 5. Install ffmpeg if missing (required to merge separate video/audio streams) ===
if [[ "$ffmpeg_installed" = false ]]; then
  echo
  echo "📥 Installing ffmpeg via Homebrew (needed to merge video+audio into a single file)..."
  brew install ffmpeg
  install_status=$?

  if [[ $install_status -ne 0 ]] && ! command -v "$ffmpeg_bin" >/dev/null 2>&1; then
    echo "❌ ffmpeg install failed (Homebrew)."
    echo "⚠️  Try running manually: brew install ffmpeg"
    exit 1
  fi
  if command -v "$ffmpeg_bin" >/dev/null 2>&1 || [[ -x "$ffmpeg_path" ]]; then
    echo "✅ ffmpeg installed successfully."
  else
    echo "⚠️  ffmpeg not found in PATH or at $ffmpeg_path."
    echo "   You may need to restart your terminal."
  fi
fi
echo

# === 6. Verify installation ===
echo "🧪 Verifying installation..."
echo

yt_dlp_verified=false
if command -v "$yt_dlp_bin" >/dev/null 2>&1; then
  installed_version=$("$yt_dlp_bin" --version 2>/dev/null || echo "unknown")
  installed_path=$(which "$yt_dlp_bin")
  echo "✅ yt-dlp: $installed_path (version: $installed_version)"
  yt_dlp_verified=true
elif [[ -x "$yt_dlp_path" ]]; then
  installed_version=$("$yt_dlp_path" --version 2>/dev/null || echo "unknown")
  echo "✅ yt-dlp: installed at $yt_dlp_path (version: $installed_version)"
  echo "   Run the following in a new terminal to check: yt-dlp --version"
  yt_dlp_verified=true
fi
if [[ "$yt_dlp_verified" = false ]]; then
  echo "⚠️  yt-dlp not found in PATH or at $yt_dlp_path."
  echo "   Run the following in a new terminal to check: yt-dlp --version"
  exit 1
fi

ffmpeg_verified=false
if command -v "$ffmpeg_bin" >/dev/null 2>&1; then
  ffmpeg_installed_version=$("$ffmpeg_bin" -version 2>/dev/null | head -1 || echo "unknown")
  ffmpeg_installed_path=$(which "$ffmpeg_bin")
  echo "✅ ffmpeg: $ffmpeg_installed_path ($ffmpeg_installed_version)"
  ffmpeg_verified=true
elif [[ -x "$ffmpeg_path" ]]; then
  ffmpeg_installed_version=$("$ffmpeg_path" -version 2>/dev/null | head -1 || echo "unknown")
  echo "✅ ffmpeg: installed at $ffmpeg_path ($ffmpeg_installed_version)"
  ffmpeg_verified=true
fi
if [[ "$ffmpeg_verified" = false ]]; then
  echo "⚠️  ffmpeg not found in PATH or at $ffmpeg_path."
  echo "   Run the following in a new terminal to check: ffmpeg -version"
fi

# === 7. Wrap-up ===
echo
echo "🎉 yt-dlp installation complete!"
echo
echo "💡 Next steps:"
echo "   • Download A/V merged to mp4:        yt-to-mp4 <URL>"
echo "     (alias for: yt-dlp -f \"bv*+ba/b\" --merge-output-format mp4 <URL>)"
echo "   • Or with explicit flag:            yt-to-mp4 --link <URL>"
echo "   • Download audio only (mp3):        yt-dlp -x --audio-format mp3 <URL>"
echo "   • Download playlist:                yt-dlp <playlist-URL>"
echo "   • List available formats:           yt-dlp --list-formats <URL>"
echo "   • Update yt-dlp + ffmpeg:           brew upgrade yt-dlp ffmpeg"
echo
echo "🔁 Future terminals: yt-to-mp4 is available automatically (sourced from ~/.zshrc)."
