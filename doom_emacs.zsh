#!/bin/zsh
# === doom_emacs.zsh ===
# Purpose: Full Doom Emacs setup on macOS Tahoe
# Includes: backup, install Doom, Markdown, ShellCheck
# Shell: Zsh (default on macOS)
# Author: theoneandonlywoj

echo "🧠 Starting Doom Emacs full setup..."

# === 1. Check if Emacs is installed ===
if ! command -v emacs &> /dev/null; then
    echo "❌ Emacs is not installed. Please run emacs.zsh first."
    exit 1
fi
echo "✅ Emacs found: $(emacs --version | head -n 1)"

# === 2. Check if Homebrew is installed ===
if ! command -v brew &> /dev/null; then
    echo "❌ Homebrew is not installed. Please install it first."
    exit 1
fi

# === 3. Backup existing ~/.emacs.d if it exists ===
backup_dir=""
if [[ -d ~/.emacs.d ]]; then
    timestamp=$(date "+%Y_%m_%d_%H_%M_%S")
    backup_dir="$HOME/.emacs.d.backup_$timestamp"
    echo "⚠️ Existing ~/.emacs.d found. Backing up to $backup_dir..."
    mv ~/.emacs.d "$backup_dir"
    if [[ $? -ne 0 ]]; then
        echo "❌ Failed to move ~/.emacs.d. Aborting."
        exit 1
    fi
fi

# === 4. Clone Doom Emacs ===
echo "📦 Cloning Doom Emacs repository..."
git clone --depth 1 https://github.com/doomemacs/doomemacs ~/.emacs.d
if [[ $? -ne 0 ]]; then
    echo "❌ Failed to clone Doom Emacs. Aborting."
    exit 1
fi

# === 5. Make doom script executable ===
chmod +x ~/.emacs.d/bin/doom
if [[ $? -ne 0 ]]; then
    echo "❌ Failed to make doom script executable. Aborting."
    exit 1
fi

# === 6. Preserve existing Doom config if present ===
if [[ -d ~/.doom.d ]]; then
    echo "✅ Existing ~/.doom.d configuration detected. It will NOT be replaced."
else
    echo "📁 Creating new ~/.doom.d folder..."
    mkdir -p ~/.doom.d
fi

# === 7. Run Doom installer ===
echo "⚙️ Running Doom Emacs installer..."
~/.emacs.d/bin/doom install
if [[ $? -ne 0 ]]; then
    echo "❌ Doom installer failed."
    exit 1
fi

# === 8. Add Doom to PATH in .zshrc ===
doom_path_line='export PATH="$HOME/.emacs.d/bin:$PATH"'
if ! grep -q '.emacs.d/bin' ~/.zshrc 2>/dev/null; then
    echo "" >> ~/.zshrc
    echo "# Doom Emacs" >> ~/.zshrc
    echo "$doom_path_line" >> ~/.zshrc
    echo "✅ Doom Emacs added to PATH in ~/.zshrc"
else
    echo "✅ Doom path already in ~/.zshrc"
fi

# Source the updated PATH for this session
export PATH="$HOME/.emacs.d/bin:$PATH"

# === 9. Doom sync ===
echo "🔄 Running 'doom sync'..."
~/.emacs.d/bin/doom sync
if [[ $? -ne 0 ]]; then
    echo "❌ Doom sync failed. Please run manually."
else
    echo "✅ Doom sync completed successfully."
fi

# === 10. Install Markdown and ShellCheck ===
echo "📚 Installing Markdown and ShellCheck..."
brew install markdown shellcheck

# === 11. Reminder for Nerd Fonts ===
echo
echo "🎨 Nerd Fonts installation is not automated in this script."
echo "   To remove Doom doctor warnings about missing fonts, please:"
echo "   1. Open Doom Emacs: emacs"
echo "   2. Run: M-x nerd-icons-install-fonts"
echo "   3. Restart Emacs after installation"
echo "💡 This will install the necessary Nerd Fonts for icons and UI."

echo
echo "🚀 Doom Emacs setup complete!"
echo "📚 Your existing configuration in ~/.doom.d has been preserved."
if [[ -n "$backup_dir" ]]; then
    echo "📦 Backup of previous ~/.emacs.d: $backup_dir"
fi

echo
echo "═══════════════════════════════════════════════════════════════════"
echo "📖 SECOND BRAIN (ORG-ROAM) - Custom Configuration"
echo "═══════════════════════════════════════════════════════════════════"
echo
echo "Your config sets up a Second Brain in ~/Desktop/Repos/Second-Brain/"
echo "with these directories:"
echo "   • 1.Notes/     → Your knowledge base (org-roam notes)"
echo "   • 2.Templates/ → Note templates"
echo "   • 3.Journal/   → Daily journal entries"
echo "   • 4.Archived/  → Archived notes"
echo
echo "Custom Keybindings (SPC = Space key in Evil/Vim mode):"
echo "   SPC n p   → Create new note from template"
echo "   SPC n j   → Create daily journal note"
echo "   SPC n d   → Archive current note"
echo "   SPC n r f → Find org-roam node"
echo "   SPC n r i → Insert org-roam link"
echo
echo "Code & Editing:"
echo "   SPC e d d → Delete current line"
echo "   SPC i b   → Insert example block"
echo "   SPC i c e → Insert Elixir code block"
echo
echo "Window Management (auto-focuses new window):"
echo "   SPC w v   → Split window right"
echo "   SPC w s   → Split window below"
echo
echo "Org-roam UI (visual graph of your notes):"
echo "   M-x org-roam-ui-mode → Open graph in browser"

echo
echo "═══════════════════════════════════════════════════════════════════"
echo "🖥️  TERMINAL IN DOOM EMACS"
echo "═══════════════════════════════════════════════════════════════════"
echo
echo "Doom Emacs supports multiple terminal options (enable in init.el):"
echo "   • vterm   → Best terminal emulation (recommended)"
echo "   • eshell  → Elisp shell, works everywhere"
echo "   • term    → Basic terminal"
echo
echo "To enable vterm, uncomment 'vterm' in ~/.doom.d/init.el under :term"
echo "then run: doom sync && brew install cmake libtool"
echo
echo "Terminal Keybindings:"
echo "   SPC o t   → Open terminal (vterm/eshell)"
echo "   SPC o T   → Open terminal in current directory"
echo "   C-c C-z   → Toggle between terminal and buffer"
echo
echo "Inside vterm:"
echo "   C-c C-t   → Toggle between line and char mode"
echo "   C-\\       → Send next key literally to terminal"

echo
echo "═══════════════════════════════════════════════════════════════════"
echo "⌨️  ESSENTIAL DOOM EMACS SHORTCUTS"
echo "═══════════════════════════════════════════════════════════════════"
echo
echo "Navigation:"
echo "   SPC .     → Find file"
echo "   SPC ,     → Switch buffer"
echo "   SPC SPC   → Find file in project"
echo "   SPC f r   → Recent files"
echo "   SPC s p   → Search in project (ripgrep)"
echo "   SPC s s   → Search in buffer"
echo
echo "Buffers & Windows:"
echo "   SPC b k   → Kill buffer"
echo "   SPC b b   → Switch buffer"
echo "   SPC w d   → Delete window"
echo "   SPC w m   → Maximize window"
echo
echo "Git (Magit):"
echo "   SPC g g   → Open Magit status"
echo "   SPC g s   → Stage current file"
echo "   SPC g c   → Commit"
echo
echo "Help:"
echo "   SPC h d h → Doom documentation"
echo "   SPC h k   → Describe key"
echo "   SPC h f   → Describe function"
echo "   SPC h v   → Describe variable"
echo
echo "Doom Commands (run in terminal):"
echo "   doom sync    → Sync packages after config changes"
echo "   doom upgrade → Upgrade Doom Emacs"
echo "   doom doctor  → Check for issues"
echo "   doom env     → Refresh environment variables"

echo
echo "═══════════════════════════════════════════════════════════════════"
echo "💡 NEXT STEPS"
echo "═══════════════════════════════════════════════════════════════════"
echo
echo "   1. Restart your terminal to update PATH"
echo "   2. Run 'doom doctor' to check for issues"
echo "   3. Copy your config: cp -r .doom.d ~/.doom.d && doom sync"
echo "   4. Launch Emacs: emacs"
echo "   5. Install Nerd Fonts: M-x nerd-icons-install-fonts"
echo
echo "📚 Doom Docs: https://github.com/doomemacs/doomemacs/blob/master/docs/index.org"
