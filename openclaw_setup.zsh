#!/bin/zsh
# === OpenClaw macOS Setup Script ===
# Author: theoneandonlywoj
# Description:
#   Installs Xcode Command Line Tools, verifies Git,
#   installs Homebrew package manager, disables sleep (Mac Mini),
#   Tailscale VPN, Jira CLI, Okta Verify, Claude Code, GitHub CLI,
#   and OpenClaw. Skips steps that are already completed.

echo "🦞 OpenClaw macOS Setup Script"
echo "----------------------------------------------------"
echo

# === 1. Pre-flight Check ===
echo "🔍 Checking current setup status..."

xcode_installed=false
git_installed=false
brew_installed=false
sleep_disabled=false
screensaver_disabled=false
caffeinate_running=false
dock_cleaned=false
tailscale_installed=false
jira_installed=false
okta_installed=false
claude_installed=false
gh_installed=false
openclaw_installed=false
gateway_installed=false

if xcode-select -p >/dev/null 2>&1; then
  xcode_installed=true
  echo "✅ Xcode Command Line Tools: Installed"
else
  echo "❌ Xcode Command Line Tools: Not installed"
fi

if command -v git >/dev/null 2>&1; then
  git_installed=true
  echo "✅ Git: Installed ($(git --version))"
else
  echo "❌ Git: Not installed"
fi

if command -v brew >/dev/null 2>&1; then
  brew_installed=true
  echo "✅ Homebrew: Installed ($(brew --version | head -n1))"
else
  echo "❌ Homebrew: Not installed"
fi

if pmset -g 2>/dev/null | grep -q "sleep.*0"; then
  sleep_disabled=true
  echo "✅ Sleep Disabled: Yes"
else
  echo "❌ Sleep Disabled: No"
fi

# Check if screen saver is disabled (idleTime = 0)
screensaver_idle=$(defaults -currentHost read com.apple.screensaver idleTime 2>/dev/null)
if [[ "$screensaver_idle" == "0" ]]; then
  screensaver_disabled=true
  echo "✅ Screen Saver Disabled: Yes"
else
  echo "❌ Screen Saver Disabled: No"
fi

# Check if caffeinate LaunchDaemon is installed and running
if [[ -f "/Library/LaunchDaemons/com.openclaw.caffeinate.plist" ]] && launchctl list 2>/dev/null | grep -q "com.openclaw.caffeinate"; then
  caffeinate_running=true
  echo "✅ Caffeinate Daemon: Running"
else
  echo "❌ Caffeinate Daemon: Not running"
fi

# Check if dock has been cleaned (Messages app removed as indicator)
if command -v dockutil >/dev/null 2>&1; then
  if ! dockutil --list 2>/dev/null | grep -q "Messages"; then
    dock_cleaned=true
    echo "✅ Dock Cleaned: Yes"
  else
    echo "❌ Dock Cleaned: No"
  fi
else
  echo "❌ Dock Cleaned: No (dockutil not installed)"
fi

if [[ -d "/Applications/Tailscale.app" ]]; then
  tailscale_installed=true
  echo "✅ Tailscale: Installed"
else
  echo "❌ Tailscale: Not installed"
fi

if command -v jira >/dev/null 2>&1; then
  jira_installed=true
  echo "✅ Jira CLI: Installed"
else
  echo "❌ Jira CLI: Not installed"
fi

if [[ -d "/Applications/Okta Verify.app" ]]; then
  okta_installed=true
  echo "✅ Okta Verify: Installed"
else
  echo "❌ Okta Verify: Not installed"
fi

if command -v claude >/dev/null 2>&1; then
  claude_installed=true
  echo "✅ Claude Code: Installed"
else
  echo "❌ Claude Code: Not installed"
fi

if command -v gh >/dev/null 2>&1; then
  gh_installed=true
  echo "✅ GitHub CLI: Installed"
else
  echo "❌ GitHub CLI: Not installed"
fi

if command -v openclaw >/dev/null 2>&1; then
  openclaw_installed=true
  echo "✅ OpenClaw: Installed"
else
  echo "❌ OpenClaw: Not installed"
fi

if openclaw gateway status >/dev/null 2>&1; then
  gateway_installed=true
  echo "✅ OpenClaw Gateway: Installed"
else
  echo "❌ OpenClaw Gateway: Not installed"
fi

echo

# Check if everything is already set up
if [[ "$xcode_installed" == "true" && "$git_installed" == "true" && "$brew_installed" == "true" && "$sleep_disabled" == "true" && "$screensaver_disabled" == "true" && "$caffeinate_running" == "true" && "$dock_cleaned" == "true" && "$tailscale_installed" == "true" && "$jira_installed" == "true" && "$okta_installed" == "true" && "$claude_installed" == "true" && "$gh_installed" == "true" && "$openclaw_installed" == "true" && "$gateway_installed" == "true" ]]; then
  echo "🎉 Everything is already set up!"
  echo "➡️  Nothing to do. Your system is ready."
  echo "----------------------------------------------------"
  exit 0
fi

# === 2. Install Xcode Command Line Tools ===
echo "🔧 Step 1: Xcode Command Line Tools"
echo

if [[ "$xcode_installed" == "true" ]]; then
  echo "ℹ️  Xcode Command Line Tools already installed. Skipping..."
else
  echo "📥 Installing Xcode Command Line Tools..."
  echo "⚠️  A dialog will appear. Please click 'Install' and wait for completion."
  echo
  
  xcode-select --install 2>/dev/null
  
  # Wait for installation to complete
  echo "⏳ Waiting for Xcode Command Line Tools installation to complete..."
  echo "   (This may take several minutes)"
  echo
  
  # Poll until xcode-select -p succeeds
  while ! xcode-select -p >/dev/null 2>&1; do
    sleep 5
  done
  
  if xcode-select -p >/dev/null 2>&1; then
    echo "✅ Xcode Command Line Tools installed successfully!"
  else
    echo "❌ Xcode Command Line Tools installation failed."
    echo "⚠️  Please try running 'xcode-select --install' manually."
    exit 1
  fi
fi

echo

# === 3. Verify Git Installation ===
echo "🔧 Step 2: Git Verification"
echo

if command -v git >/dev/null 2>&1; then
  git_version=$(git --version)
  echo "✅ Git is available!"
  echo "   $git_version"
else
  echo "❌ Git is not available."
  echo "⚠️  Git should be bundled with Xcode Command Line Tools."
  echo "   Please verify Xcode CLI tools are properly installed."
  exit 1
fi

echo

# === 4. Install Homebrew ===
echo "🔧 Step 3: Homebrew Installation"
echo

if [[ "$brew_installed" == "true" ]]; then
  echo "ℹ️  Homebrew already installed. Skipping..."
else
  # Detect CPU architecture (Intel vs Apple Silicon)
  echo "🧠 Detecting system architecture..."
  arch_name=$(uname -m)
  if [[ "$arch_name" == "arm64" ]]; then
    echo "🍏 Detected Apple Silicon (M1/M2/M3/M4)..."
    brew_path="/opt/homebrew/bin/brew"
    brew_shell_line='eval "$(/opt/homebrew/bin/brew shellenv)"'
  else
    echo "💻 Detected Intel-based Mac..."
    brew_path="/usr/local/bin/brew"
    brew_shell_line='eval "$(/usr/local/bin/brew shellenv)"'
  fi
  echo

  # Install Homebrew
  echo "📥 Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [[ $? -ne 0 ]]; then
    echo "❌ Homebrew installation failed!"
    echo "⚠️  Please check your internet connection or permissions."
    exit 1
  fi

  echo
  echo "✅ Homebrew installation completed successfully."

  # Configure PATH for Zsh
  echo "🔧 Adding Homebrew to PATH..."

  # Append brew init line if not already in .zprofile
  if ! grep -q "$brew_shell_line" ~/.zprofile 2>/dev/null; then
    echo "$brew_shell_line" >> ~/.zprofile
    echo "📄 Updated ~/.zprofile with Homebrew path"
  else
    echo "ℹ️  Homebrew path already configured in ~/.zprofile"
  fi

  # Apply immediately to current shell session
  eval "$brew_shell_line"

  # Verify installation
  echo
  echo "🧪 Verifying Homebrew installation..."
  if command -v brew >/dev/null 2>&1; then
    brew_version=$(brew --version | head -n1)
    echo "✅ Homebrew is ready to use!"
    echo "   $brew_version"
  else
    echo "❌ Homebrew not found in PATH."
    echo "⚙️  Try restarting your terminal or running:"
    echo "   $brew_shell_line"
    exit 1
  fi
fi

echo

# === 5. Disable Sleep (Mac Mini) ===
echo "🔧 Step 4: Disable Sleep (Mac Mini)"
echo

if [[ "$sleep_disabled" == "true" ]]; then
  echo "ℹ️  Sleep already disabled. Skipping..."
else
  echo "💤 Disabling all sleep and power-off modes..."
  echo "⚠️  This requires administrator privileges."
  echo
  echo "   Configuring power settings:"
  echo "   • displaysleep 0    - Never turn off display"
  echo "   • sleep 0           - Never sleep"
  echo "   • disksleep 0       - Never spin down disks"
  echo "   • standby 0         - Disable standby mode"
  echo "   • autopoweroff 0    - Disable automatic power off"
  echo "   • hibernatemode 0   - Disable hibernation"
  echo "   • networkoversleep 1 - Keep network active during sleep"
  echo "   • womp 1            - Wake on network access"
  echo "   • powernap 0        - Disable Power Nap"
  echo "   • ttyskeepawake 1   - Prevent sleep during remote sessions"
  echo
  
  sudo pmset -a \
    displaysleep 0 \
    sleep 0 \
    disksleep 0 \
    standby 0 \
    autopoweroff 0 \
    hibernatemode 0 \
    networkoversleep 1 \
    womp 1 \
    powernap 0 \
    ttyskeepawake 1

  if [[ $? -ne 0 ]]; then
    echo "❌ Failed to disable sleep!"
    echo "⚠️  Please try running the pmset command manually."
    exit 1
  fi

  echo "✅ All sleep and power-off modes disabled!"
  echo
  echo "💡 To restore default power settings later:"
  echo "   • Run: sudo pmset -a displaysleep 10 sleep 1 disksleep 10 standby 1 autopoweroff 1 hibernatemode 3 networkoversleep 0 womp 0 powernap 1 ttyskeepawake 0"
fi

echo

# === 6. Disable Screen Saver and Screen Lock (Mac Mini) ===
echo "🔧 Step 5: Disable Screen Saver and Screen Lock (Mac Mini)"
echo

if [[ "$screensaver_disabled" == "true" ]]; then
  echo "ℹ️  Screen saver already disabled. Skipping..."
else
  echo "🖥️  Disabling screen saver and screen lock..."
  
  # Disable screen saver (set idle time to 0 = never)
  defaults -currentHost write com.apple.screensaver idleTime 0
  
  # Disable password requirement after screen saver / sleep
  defaults write com.apple.screensaver askForPassword -int 0
  defaults write com.apple.screensaver askForPasswordDelay -int 0
  
  # Clear screen saver module (no screen saver)
  defaults -currentHost write com.apple.screensaver moduleDict -dict moduleName -string "" path -string ""
  
  # Refresh preferences daemon
  killall cfprefsd 2>/dev/null || true

  echo "✅ Screen saver and screen lock disabled successfully!"
  echo
  echo "💡 To restore default screen saver settings later:"
  echo "   • Run: defaults -currentHost write com.apple.screensaver idleTime 300"
  echo "   • Run: defaults write com.apple.screensaver askForPassword -int 1"
fi

echo

# === 7. Install Caffeinate Daemon (Mac Mini) ===
echo "🔧 Step 6: Install Caffeinate Daemon (Mac Mini)"
echo

if [[ "$caffeinate_running" == "true" ]]; then
  echo "ℹ️  Caffeinate daemon already running. Skipping..."
else
  echo "☕ Installing caffeinate as a LaunchDaemon..."
  echo "⚠️  This requires administrator privileges."
  echo "   Caffeinate prevents the system from sleeping even if power settings are changed."
  
  # Create the LaunchDaemon plist
  caffeinate_plist="/Library/LaunchDaemons/com.openclaw.caffeinate.plist"
  
  sudo tee "$caffeinate_plist" > /dev/null << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.openclaw.caffeinate</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/caffeinate</string>
        <string>-dimsu</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
PLIST

  if [[ $? -ne 0 ]]; then
    echo "❌ Failed to create caffeinate LaunchDaemon!"
    echo "⚠️  Please try creating the plist manually."
    exit 1
  fi

  # Set correct permissions
  sudo chown root:wheel "$caffeinate_plist"
  sudo chmod 644 "$caffeinate_plist"

  # Load the daemon
  sudo launchctl load "$caffeinate_plist"

  if [[ $? -ne 0 ]]; then
    echo "❌ Failed to load caffeinate daemon!"
    echo "⚠️  Please try running 'sudo launchctl load $caffeinate_plist' manually."
    exit 1
  fi

  echo "✅ Caffeinate daemon installed and running!"
  echo
  echo "💡 Caffeinate flags used:"
  echo "   • -d: Prevent display sleep"
  echo "   • -i: Prevent idle sleep"
  echo "   • -m: Prevent disk sleep"
  echo "   • -s: Prevent system sleep (AC power)"
  echo "   • -u: Declare user activity"
  echo
  echo "💡 To stop caffeinate later:"
  echo "   • Run: sudo launchctl unload /Library/LaunchDaemons/com.openclaw.caffeinate.plist"
  echo "   • Run: sudo rm /Library/LaunchDaemons/com.openclaw.caffeinate.plist"
fi

echo

# === 8. Clean Up Dock ===
echo "🔧 Step 7: Clean Up Dock"
echo

if [[ "$dock_cleaned" == "true" ]]; then
  echo "ℹ️  Dock already cleaned. Skipping..."
else
  # Install dockutil if not present
  if ! command -v dockutil >/dev/null 2>&1; then
    echo "📥 Installing dockutil..."
    brew install dockutil
    
    if [[ $? -ne 0 ]]; then
      echo "❌ dockutil installation failed!"
      echo "⚠️  Please try running 'brew install dockutil' manually."
      exit 1
    fi
  fi

  echo "🧹 Removing default apps from Dock..."
  
  # List of apps to remove from dock
  apps_to_remove=(
    "Messages"
    "Mail"
    "Maps"
    "Photos"
    "FaceTime"
    "Calendar"
    "Contacts"
    "Notes"
    "Freeform"
    "TV"
    "Music"
    "Keynote"
    "Numbers"
    "Pages"
  )
  
  for app in "${apps_to_remove[@]}"; do
    if dockutil --list 2>/dev/null | grep -q "$app"; then
      dockutil --remove "$app" --no-restart >/dev/null 2>&1
      echo "   ✓ Removed $app"
    fi
  done
  
  # Restart Dock to apply changes
  killall Dock
  
  echo "✅ Dock cleaned successfully!"
fi

echo

# === 9. Install Tailscale ===
echo "🔧 Step 8: Tailscale Installation"
echo

if [[ "$tailscale_installed" == "true" ]]; then
  echo "ℹ️  Tailscale already installed. Skipping..."
else
  echo "📥 Installing Tailscale..."
  brew install --cask tailscale

  if [[ $? -ne 0 ]]; then
    echo "❌ Tailscale installation failed!"
    echo "⚠️  Please try running 'brew install --cask tailscale' manually."
    exit 1
  fi

  echo "✅ Tailscale installed successfully!"
  echo
  echo "💡 To start Tailscale:"
  echo "   • Open Tailscale from Applications"
  echo "   • Or run: open /Applications/Tailscale.app"
fi

echo

# === 10. Install Jira CLI ===
echo "🔧 Step 9: Jira CLI Installation"
echo

if [[ "$jira_installed" == "true" ]]; then
  echo "ℹ️  Jira CLI already installed. Skipping..."
else
  echo "📥 Installing Jira CLI..."
  brew install jira-cli

  if [[ $? -ne 0 ]]; then
    echo "❌ Jira CLI installation failed!"
    echo "⚠️  Please try running 'brew install jira-cli' manually."
    exit 1
  fi

  echo "✅ Jira CLI installed successfully!"
  echo
  echo "💡 To configure Jira CLI:"
  echo "   • Run: jira init"
  echo "   • Follow the prompts to connect to your Jira instance"
fi

echo

# === 11. Install Okta Verify ===
echo "🔧 Step 10: Okta Verify Installation"
echo

if [[ "$okta_installed" == "true" ]]; then
  echo "ℹ️  Okta Verify already installed. Skipping..."
else
  echo "📥 Installing Okta Verify..."
  brew install --cask okta-verify

  if [[ $? -ne 0 ]]; then
    echo "❌ Okta Verify installation failed!"
    echo "⚠️  Please try running 'brew install --cask okta-verify' manually."
    exit 1
  fi

  echo "✅ Okta Verify installed successfully!"
  echo
  echo "💡 To set up Okta Verify:"
  echo "   • Open Okta Verify from Applications"
  echo "   • Follow the prompts to add your organization"
fi

echo

# === 12. Install Claude Code ===
echo "🔧 Step 11: Claude Code Installation"
echo

if [[ "$claude_installed" == "true" ]]; then
  echo "ℹ️  Claude Code already installed. Skipping..."
else
  echo "📥 Installing Claude Code..."
  curl -fsSL https://claude.ai/install.sh | bash

  if [[ $? -ne 0 ]]; then
    echo "❌ Claude Code installation failed!"
    echo "⚠️  Please try running 'curl -fsSL https://claude.ai/install.sh | bash' manually."
    exit 1
  fi

  echo "✅ Claude Code installed successfully!"
  echo
  echo "💡 To use Claude Code:"
  echo "   • Run: claude"
  echo "   • Or run: claude --help for available commands"
fi

echo

# === 13. Install GitHub CLI ===
echo "🔧 Step 12: GitHub CLI Installation"
echo

if [[ "$gh_installed" == "true" ]]; then
  echo "ℹ️  GitHub CLI already installed. Skipping..."
else
  echo "📥 Installing GitHub CLI..."
  brew install gh

  if [[ $? -ne 0 ]]; then
    echo "❌ GitHub CLI installation failed!"
    echo "⚠️  Please try running 'brew install gh' manually."
    exit 1
  fi

  echo "✅ GitHub CLI installed successfully!"
  echo
  echo "💡 To configure GitHub CLI:"
  echo "   • Run: gh auth login"
  echo "   • Follow the prompts to authenticate with GitHub"
fi

echo

# === 14. Install OpenClaw ===
echo "🔧 Step 13: OpenClaw Installation"
echo

if [[ "$openclaw_installed" == "true" ]]; then
  echo "ℹ️  OpenClaw already installed. Skipping..."
else
  echo "📥 Installing OpenClaw..."
  curl -fsSL https://openclaw.ai/install.sh | bash

  if [[ $? -ne 0 ]]; then
    echo "❌ OpenClaw installation failed!"
    echo "⚠️  Please try running 'curl -fsSL https://openclaw.ai/install.sh | bash' manually."
    exit 1
  fi

  echo "✅ OpenClaw installed successfully!"
  echo
  echo "💡 To use OpenClaw:"
  echo "   • Run: openclaw"
  echo "   • Or run: openclaw --help for available commands"
fi

echo

# === 15. Install OpenClaw Gateway ===
echo "🔧 Step 14: OpenClaw Gateway Installation"
echo

if [[ "$gateway_installed" == "true" ]]; then
  echo "ℹ️  OpenClaw Gateway already installed. Skipping..."
else
  echo "📥 Installing OpenClaw Gateway..."
  openclaw gateway install

  if [[ $? -ne 0 ]]; then
    echo "❌ OpenClaw Gateway installation failed!"
    echo "⚠️  Please try running 'openclaw gateway install' manually."
    exit 1
  fi

  echo "✅ OpenClaw Gateway installed successfully!"
fi

echo

# === 16. Summary ===
echo "----------------------------------------------------"
echo "🎉 OpenClaw Setup Complete!"
echo
echo "📋 Installed Components:"
echo "   • Xcode Command Line Tools: $(xcode-select -p 2>/dev/null || echo 'N/A')"
echo "   • Git: $(git --version 2>/dev/null || echo 'N/A')"
echo "   • Homebrew: $(brew --version 2>/dev/null | head -n1 || echo 'N/A')"
echo "   • Sleep Disabled: $(pmset -g 2>/dev/null | grep -q 'sleep.*0' && echo 'Yes' || echo 'No')"
echo "   • Screen Saver Disabled: $([[ "$(defaults -currentHost read com.apple.screensaver idleTime 2>/dev/null)" == "0" ]] && echo 'Yes' || echo 'No')"
echo "   • Caffeinate Daemon: $([[ -f '/Library/LaunchDaemons/com.openclaw.caffeinate.plist' ]] && launchctl list 2>/dev/null | grep -q 'com.openclaw.caffeinate' && echo 'Running' || echo 'N/A')"
echo "   • Dock Cleaned: $(command -v dockutil >/dev/null 2>&1 && ! dockutil --list 2>/dev/null | grep -q 'Messages' && echo 'Yes' || echo 'No')"
echo "   • Tailscale: $([[ -d '/Applications/Tailscale.app' ]] && echo 'Installed' || echo 'N/A')"
echo "   • Jira CLI: $(command -v jira >/dev/null 2>&1 && echo 'Installed' || echo 'N/A')"
echo "   • Okta Verify: $([[ -d '/Applications/Okta Verify.app' ]] && echo 'Installed' || echo 'N/A')"
echo "   • Claude Code: $(command -v claude >/dev/null 2>&1 && echo 'Installed' || echo 'N/A')"
echo "   • GitHub CLI: $(command -v gh >/dev/null 2>&1 && echo 'Installed' || echo 'N/A')"
echo "   • OpenClaw: $(command -v openclaw >/dev/null 2>&1 && echo 'Installed' || echo 'N/A')"
echo "   • OpenClaw Gateway: $(openclaw gateway status >/dev/null 2>&1 && echo 'Installed' || echo 'N/A')"
echo
echo "💡 Next steps:"
echo "   • Sleep/power-off disabled - to restore: sudo pmset -a displaysleep 10 sleep 1 disksleep 10 standby 1 autopoweroff 1 hibernatemode 3"
echo "   • Screen saver disabled - to restore: defaults -currentHost write com.apple.screensaver idleTime 300"
echo "   • Caffeinate daemon running - to stop: sudo launchctl unload /Library/LaunchDaemons/com.openclaw.caffeinate.plist"
echo "   • Run 'brew doctor' to verify Homebrew setup"
echo "   • Open Tailscale and sign in to your account"
echo "   • Run 'jira init' to configure Jira CLI"
echo "   • Open Okta Verify and add your organization (or add it from your Mac with Open Okta Verify -> Add Account to another device)"
echo "   • Run 'claude' to start using Claude Code"
echo "   • Run 'gh auth login' to authenticate GitHub CLI"
echo "   • Run 'openclaw' to start using OpenClaw"
echo "   • Configure Git with your name and email (optional)"
echo "   • Set up SSH keys for GitHub (optional)"
echo
echo "✨ Your Mac is ready for OpenClaw bot!"
echo "----------------------------------------------------"
