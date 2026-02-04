#!/bin/zsh
# === emacs.zsh ===
# Purpose: Install Emacs 30 on macOS Tahoe using Homebrew emacs-plus
# Shell: Zsh (default on macOS)
# Author: theoneandonlywoj

echo "🧠 Welcome to Emacs 30 installer for macOS Tahoe"
echo

# === 1. Check if Homebrew is installed ===
if ! command -v brew &> /dev/null; then
    echo "❌ Homebrew is not installed. Please install it first:"
    echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    exit 1
fi
echo "✅ Homebrew is installed"

# === 2. Update Homebrew (optional) ===
echo
echo -n "Would you like to update Homebrew before installing Emacs? (Y/n) "
read update_choice
if [[ -z "$update_choice" || "${update_choice:l}" == "y" ]]; then
    echo "🔄 Updating Homebrew..."
    brew update
    if [[ $? -ne 0 ]]; then
        echo "❌ Homebrew update failed. Please check your internet connection."
        exit 1
    fi
else
    echo "⚠️ Skipping Homebrew update."
fi

# === 3. Check if Emacs is already installed ===
if command -v emacs &> /dev/null; then
    version=$(emacs --version | head -n 1)
    echo "✅ $version is already installed."
    echo -n "Do you want to reinstall or upgrade to Emacs 30? (y/N) "
    read reinstall
    if [[ "${reinstall:l}" != "y" ]]; then
        echo "➡️  Keeping current Emacs installation."
        exit 0
    fi
fi

# === 4. Add emacs-plus tap ===
echo
echo "🍺 Adding d12frosted/emacs-plus tap..."
brew tap d12frosted/emacs-plus
if [[ $? -ne 0 ]]; then
    echo "❌ Failed to add emacs-plus tap."
    exit 1
fi

# === 5. Install Emacs 30 ===
# Note: Native compilation is enabled by default in emacs-plus@30
echo
echo "⚙️ Installing Emacs 30..."
echo "   This may take a while as it compiles from source..."
echo

brew install emacs-plus@30 --with-imagemagick
if [[ $? -ne 0 ]]; then
    echo "❌ Emacs installation failed."
    exit 1
fi

# === 6. Link Emacs.app to /Applications ===
echo
echo "🔗 Linking Emacs.app to /Applications..."
if [[ -d "/Applications/Emacs.app" ]]; then
    echo "⚠️ /Applications/Emacs.app already exists. Removing old link..."
    rm -rf "/Applications/Emacs.app"
fi
osascript -e 'tell application "Finder" to make alias file to POSIX file "/opt/homebrew/opt/emacs-plus@30/Emacs.app" at POSIX file "/Applications" with properties {name:"Emacs.app"}'
if [[ $? -ne 0 ]]; then
    echo "⚠️ Could not create alias. Trying symbolic link instead..."
    ln -sf /opt/homebrew/opt/emacs-plus@30/Emacs.app /Applications/Emacs.app
fi
echo "✅ Emacs.app linked to /Applications"

# === 7. Offer optional extras ===
echo
echo "✨ Optional tools that supercharge Emacs:"
echo "   - git       → version control integration"
echo "   - ripgrep   → ultra-fast search inside projects"
echo "   - fd        → better file finding"
echo

echo -n "Do you want to install these recommended tools? (Y/n) "
read extras
if [[ -z "$extras" || "${extras:l}" == "y" ]]; then
    echo "📦 Installing recommended tools..."
    brew install git ripgrep fd
fi

# === 8. Confirm success ===
echo
if command -v emacs &> /dev/null; then
    version=$(emacs --version | head -n 1)
    echo "✅ Installation successful! $version is now available."
    echo
    echo "🚀 You can start Emacs with:"
    echo "   • Terminal: emacs"
    echo "   • GUI: Open Emacs.app from /Applications or Spotlight"
    echo
    echo "📚 Docs: https://www.gnu.org/software/emacs/"
else
    echo "⚠️ Emacs installation completed but command not found."
    echo "   Try restarting your terminal or running: brew link emacs-plus@30"
fi
