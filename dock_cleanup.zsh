#!/bin/zsh
# === dock_cleanup.zsh ===
# Purpose: Clean up the macOS Dock and add installed apps in a defined order
# Author: theoneandonlywoj
# Requirements: Homebrew (dockutil will be installed automatically if missing)
#
# Run this script LAST after installing all apps. It will:
#   1. Install dockutil if missing
#   2. Back up the current Dock plist
#   3. Remove unwanted default macOS apps from the Dock
#   4. Add installed apps in order: Chrome, Vivaldi, Slack, VSCode, OpenCode, Postman, 1Password
#   5. Restart the Dock once

# === Apps to remove from Dock (default macOS apps) ===
apps_to_remove=(
  "Safari"
  "Messages"
  "Mail"
  "Maps"
  "Photos"
  "FaceTime"
  "Calendar"
  "Contacts"
  "TV"
  "Music"
  "Keynote"
  "Numbers"
  "Pages"
)

# === Apps to add to Dock (in order, left to right) ===
# Format: "Display Name|Path"
apps_to_add=(
  "Google Chrome|/Applications/Google Chrome.app"
  "Vivaldi|/Applications/Vivaldi.app"
  "Slack|/Applications/Slack.app"
  "Visual Studio Code|/Applications/Visual Studio Code.app"
  "OpenCode|/Applications/OpenCode.app"
  "Postman|/Applications/Postman.app"
  "1Password|/Applications/1Password.app"
)

backup_plist=~/Desktop/com.apple.dock.backup.plist

echo "🚀 Starting Dock cleanup and setup (macOS Tahoe)..."
echo

# === 1. Ensure dockutil is installed ===
if ! command -v dockutil >/dev/null 2>&1; then
  echo "⚙️  dockutil not found. Installing via Homebrew..."
  if ! command -v brew >/dev/null 2>&1; then
    echo "❌ Homebrew is not installed. Please install Homebrew first."
    echo "   Run: ./brew.zsh"
    exit 1
  fi
  brew install dockutil
  if [[ $? -ne 0 ]]; then
    echo "❌ Failed to install dockutil. Aborting."
    exit 1
  fi
  echo "✅ dockutil installed successfully."
else
  echo "✅ dockutil is already installed."
fi

# === 2. Backup current Dock plist ===
echo "💾 Backing up current Dock plist to $backup_plist..."
cp ~/Library/Preferences/com.apple.dock.plist "$backup_plist"
if [[ $? -eq 0 ]]; then
  echo "✅ Backup complete!"
else
  echo "⚠️  Backup failed, aborting."
  exit 1
fi

# === 3. Remove unwanted default apps from Dock ===
echo
echo "🗑️  Removing unwanted default apps from Dock..."
removed_apps=()
skipped_apps=()

for app in $apps_to_remove; do
  if dockutil --find "$app" >/dev/null 2>&1; then
    echo "   🗑️  Removing $app from Dock..."
    dockutil --remove "$app" --no-restart
    removed_apps+=("$app")
  else
    skipped_apps+=("$app")
  fi
done

echo "✅ Removed ${#removed_apps} default apps from Dock."

# === 4. Add installed apps to Dock in order ===
echo
echo "📌 Adding installed apps to Dock..."
added_apps=()
not_installed=()

for entry in "${apps_to_add[@]}"; do
  app_name="${entry%%|*}"
  app_path="${entry#*|}"

  if [[ -d "$app_path" ]]; then
    # Remove existing entry first (avoids duplicates)
    dockutil --remove "$app_name" --no-restart >/dev/null 2>&1
    # Add at the end of the Dock
    dockutil --add "$app_path" --no-restart
    echo "   ✅ Added $app_name"
    added_apps+=("$app_name")
  else
    echo "   ⏭️  Skipped $app_name (not installed at $app_path)"
    not_installed+=("$app_name")
  fi
done

# === 5. Restart Dock to apply all changes ===
echo
echo "🔄 Restarting Dock to apply changes..."
killall Dock

# === 6. Summary ===
echo
echo "═══════════════════════════════════════════════════"
echo "✨ Dock cleanup and setup complete!"
echo "═══════════════════════════════════════════════════"
echo
echo "🗑️  Removed from Dock:"
if [[ ${#removed_apps[@]} -gt 0 ]]; then
  for app in ${(u)removed_apps}; do
    echo "      • $app"
  done
else
  echo "      (none)"
fi
echo
echo "ℹ️  Skipped (not in Dock):"
if [[ ${#skipped_apps[@]} -gt 0 ]]; then
  for app in ${(u)skipped_apps}; do
    echo "      • $app"
  done
else
  echo "      (none)"
fi
echo
echo "📌 Added to Dock (in order):"
if [[ ${#added_apps[@]} -gt 0 ]]; then
  for app in "${added_apps[@]}"; do
    echo "      • $app"
  done
else
  echo "      (none)"
fi
echo
echo "⏭️  Not installed (skipped):"
if [[ ${#not_installed[@]} -gt 0 ]]; then
  for app in "${not_installed[@]}"; do
    echo "      • $app"
  done
else
  echo "      (none)"
fi
echo
echo "📂 Backup saved at: $backup_plist"
echo "🧭 To restore, run:"
echo "   defaults import com.apple.dock $backup_plist && killall Dock"
echo
echo "🚀 Enjoy your Dock!"