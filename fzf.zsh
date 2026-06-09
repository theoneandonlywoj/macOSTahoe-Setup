#!/bin/zsh
# === fzf.zsh ===
# Purpose: Install fzf (fuzzy finder) on macOS Tahoe
# Shell: Zsh (default on macOS Tahoe)
# Author: theoneandonlywoj

echo "🔍 Starting fzf installation on macOS Tahoe..."
echo

# === Configuration ===
arch_name=$(uname -m)
if [[ "$arch_name" == "arm64" ]]; then
  fzf_bin="/opt/homebrew/bin/fzf"
else
  fzf_bin="/usr/local/bin/fzf"
fi
zshrc="$HOME/.zshrc"

echo "📦 Target binary: $fzf_bin"
echo

# === 1. Check if fzf is already installed ===
if command -v fzf >/dev/null 2>&1; then
  echo "✅ fzf is already installed: $(fzf --version)"
  read "reinstall?Do you want to reinstall? [y/N] "
  if [[ "$reinstall" != "y" && "$reinstall" != "Y" ]]; then
    echo "⚠️  Skipping fzf installation."
    exit 0
  fi
  echo "📦 Removing existing fzf installation..."
  brew uninstall fzf
  if [[ $? -ne 0 ]]; then
    echo "❌ Failed to remove fzf."
    exit 1
  fi
  echo "✅ fzf removed."
fi

# === 2. Check and install Homebrew if missing ===
echo
if ! command -v brew >/dev/null 2>&1; then
  echo "⚙️  Homebrew not found. Installing..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  echo "💡 Adding Homebrew to PATH..."
  if [[ -d "/opt/homebrew/bin" ]]; then
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
  echo "✅ Homebrew installed."
else
  echo "✅ Homebrew already installed."
fi

# === 3. Install fzf ===
echo
echo "📥 Installing fzf..."
brew install fzf
if [[ $? -ne 0 ]]; then
  echo "❌ Failed to install fzf."
  exit 1
fi
echo "✅ fzf installed."

# === 4. Install fzf shell integration ===
echo
echo "🔧 Setting up fzf shell integration..."

fzf_install="$(brew --prefix)/opt/fzf/install"

if [[ -x "$fzf_install" ]]; then
  echo "💡 Running fzf install script for shell key bindings and completion..."
  "$fzf_install" --key-bindings --completion --no-update-rc --zshrc
  echo "✅ fzf shell integration installed."
else
  echo "⚠️  fzf install script not found. Setting up manually..."

  touch "$zshrc"

  fzf_prefix="$(brew --prefix)/opt/fzf"

  if ! grep -q 'fzf key-bindings' "$zshrc"; then
    echo "💡 Adding fzf key bindings to ~/.zshrc..."
    echo '' >> "$zshrc"
    echo '# Initialize fzf (fuzzy finder)' >> "$zshrc"
    echo "source \"$fzf_prefix/shell/key-bindings.zsh\"" >> "$zshrc"
  fi

  if ! grep -q 'fzf completion' "$zshrc"; then
    echo "💡 Adding fzf completion to ~/.zshrc..."
    echo "source \"$fzf_prefix/shell/completion.zsh\"" >> "$zshrc"
  fi

  echo "✅ fzf integration added to ~/.zshrc."
fi

# === 5. Verify installation ===
echo
echo "🧪 Verifying installation..."
if command -v fzf >/dev/null 2>&1; then
  echo "✅ fzf installed successfully: $(fzf --version)"
else
  echo "❌ fzf installation verification failed."
  exit 1
fi

# === 6. Post-installation checks ===
echo
echo "🧪 Verifying setup..."
if command -v fzf >/dev/null 2>&1; then
  echo "✅ fzf is ready to use."
else
  echo "⚠️  fzf command not found in PATH. Restart your terminal or run:"
  echo '   source ~/.zshrc'
fi

# === 7. Tips ===
echo
echo "🎉 fzf installation complete!"
echo
echo "💡 fzf provides fuzzy matching for files, history, and more."
echo
echo "💡 Key bindings:"
echo "   Ctrl+T        Find files (fuzzy)"
echo "   Ctrl+R        Search history (fuzzy) — note: if Atuin is installed,"
echo "                  Atuin takes over Ctrl+R; use Ctrl+T for files instead"
echo "   Alt+C          Change directory (fuzzy)"
echo
echo "💡 Fuzzy completion (type trigger then Tab):"
echo "   vim **<Tab>       Fuzzy-find files to open in vim"
echo "   cd **<Tab>        Fuzzy-find directories to cd into"
echo "   kill **<Tab>      Fuzzy-find processes to kill"
echo "   ssh **<Tab>        Fuzzy-find SSH hosts"
echo "   export **<Tab>    Fuzzy-find environment variables"
echo "   unset **<Tab>     Fuzzy-find environment variables"
echo
echo "💡 Common commands:"
echo "   fzf                     Interactive fuzzy finder (pipe input to it)"
echo "   find . -type f | fzf    Find files with fuzzy matching"
echo "   cat file | fzf          Search file contents"
echo
echo "💡 Restart your terminal or run: source ~/.zshrc"