#!/bin/zsh
# === install_github_cli.zsh ===
# Purpose: Install GitHub CLI (gh) on macOS Tahoe with Zsh
# Shell: Zsh (default on macOS Tahoe)
# Author: theoneandonlywoj (style inspired)

echo "🚀 Starting GitHub CLI (gh) installation on macOS Tahoe..."
echo

# === Configuration ===
brew_path="/opt/homebrew/bin/brew"
gh_bin="/opt/homebrew/bin/gh"

echo "📦 Target binary: $gh_bin"
echo "🧠 Shell: Zsh"
echo

# === 1. Ensure Homebrew is available ===
if ! command -v brew >/dev/null 2>&1; then
  echo "⚙️  Homebrew not found. Installing..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  echo "💡 Adding Homebrew to PATH..."
  if [[ -d "/opt/homebrew/bin" ]]; then
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
  echo "✅ Homebrew installed successfully."
else
  echo "✅ Homebrew already installed."
fi

# === 2. Install GitHub CLI ===
echo
echo "📥 Installing GitHub CLI (gh)..."
if brew list gh &>/dev/null; then
  echo "ℹ️  GitHub CLI is already installed. Upgrading to latest version..."
  brew upgrade gh || echo "⚠️  Upgrade skipped (already up-to-date)."
else
  brew install gh
fi

# === 3. Verify installation ===
if command -v gh >/dev/null 2>&1; then
  echo "✅ GitHub CLI installed successfully!"
else
  echo "❌ Installation failed. Aborting."
  exit 1
fi

# === 4. Add to PATH (if necessary) ===
if [[ ":$PATH:" != *":/opt/homebrew/bin:"* ]]; then
  echo "🧩 Adding Homebrew to PATH in ~/.zshrc..."
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
  source ~/.zshrc
  echo "✅ PATH updated for Homebrew binaries."
fi

# === 5. Verify gh version ===
echo
echo "🧪 Verifying gh version..."
gh_version=$(gh --version | head -n 1)
echo "📘 $gh_version"
echo

# === 6. GitHub authentication guidance ===
if ! gh auth status >/dev/null 2>&1; then
  echo "🔐 You’re not logged in to GitHub CLI."
  echo "👉 Run the following command to authenticate:"
  echo
  echo "   gh auth login"
  echo
  echo "💡 Choose:"
  echo "   • GitHub.com (default)"
  echo "   • HTTPS (recommended)"
  echo "   • Open browser for authentication"
else
  echo "✅ GitHub CLI is already authenticated."
fi

# === 7. Install gh-stack extension ===
echo
echo "🧩 Installing gh-stack extension (github/gh-stack)..."
if gh auth status >/dev/null 2>&1; then
  if gh extension list 2>/dev/null | grep -q "github/gh-stack"; then
    echo "ℹ️  gh-stack extension is already installed. Upgrading..."
    gh extension upgrade github/gh-stack || echo "⚠️  Upgrade skipped (already up-to-date)."
  else
    gh extension install github/gh-stack
  fi
  echo "✅ gh-stack extension ready!"
else
  echo "⚠️  Skipping gh-stack extension install: GitHub CLI is not authenticated."
  echo "👉 Run 'gh auth login', then install it manually with:"
  echo "   gh extension install github/gh-stack"
fi

# === 8. Cheatsheet ===
echo
echo "🎉 GitHub CLI setup complete!"
echo
echo "════════════════════════════════════════════════════════"
echo "📘 gh CLI cheatsheet — common operations"
echo "════════════════════════════════════════════════════════"
echo
echo "🔐 Auth"
echo "   gh auth status                       # check login state"
echo "   gh auth login                        # log in"
echo
echo "📁 Repos"
echo "   gh repo create my-repo --public      # create a new repo"
echo "   gh repo clone owner/repo             # clone a repo"
echo "   gh repo view --web                   # open repo in browser"
echo "   gh repo fork owner/repo --clone      # fork + clone"
echo
echo "🔀 Pull requests"
echo "   gh pr list                           # list open PRs"
echo "   gh pr status                         # PRs relevant to you"
echo "   gh pr create --fill                  # create PR from current branch"
echo "   gh pr view 123 --web                 # open PR #123 in browser"
echo "   gh pr checkout 123                   # check out PR #123 locally"
echo "   gh pr merge 123 --squash             # squash-merge PR #123"
echo "   gh pr diff 123                       # view PR #123's diff"
echo "   gh pr review 123 --approve           # approve PR #123"
echo
echo "🐞 Issues"
echo "   gh issue list                        # list open issues"
echo "   gh issue create --title \"Bug\" --body \"...\"  # create an issue"
echo "   gh issue close 42                    # close issue #42"
echo
echo "⚙️  Workflows / CI"
echo "   gh run list                          # list recent workflow runs"
echo "   gh run watch                         # watch the latest run live"
echo "   gh workflow run deploy.yml           # trigger a workflow"
echo
echo "🧩 Extensions"
echo "   gh extension list                    # list installed extensions"
echo "   gh extension upgrade --all           # upgrade all extensions"
echo
echo "────────────────────────────────────────────────────────"
echo "📚 gh-stack cheatsheet — stacked pull requests"
echo "────────────────────────────────────────────────────────"
echo
echo "🚀 Build a stack"
echo "   gh stack init                        # start a stack (interactive)"
echo "   gh stack init feat-auth feat-api     # start a stack with named branches"
echo "   gh stack add feat-ui                 # add a new branch on top"
echo "   gh stack add -Am \"Add login\"          # stage all + commit + auto-name branch"
echo
echo "📤 Push & submit"
echo "   gh stack push                        # push all branches in the stack"
echo "   gh stack submit                      # push + open/update PRs for the stack"
echo "   gh stack submit --auto               # submit without the interactive editor"
echo
echo "🔄 Keep in sync"
echo "   gh stack sync                        # fetch, rebase, push, sync PRs (one shot)"
echo "   gh stack sync --prune                # sync + delete branches for merged PRs"
echo "   gh stack rebase                      # cascade-rebase the whole stack"
echo "   gh stack rebase --continue           # resume rebase after fixing conflicts"
echo
echo "🧭 Navigate"
echo "   gh stack view                        # show the current stack"
echo "   gh stack up / gh stack down          # move one layer up/down"
echo "   gh stack top / gh stack bottom       # jump to top/bottom of the stack"
echo "   gh stack switch                      # interactive branch picker"
echo "   gh stack checkout 7                  # check out stack #7 (or a PR #/URL)"
echo
echo "🛠️  Manage"
echo "   gh stack modify                      # reorder/drop/fold branches (TUI)"
echo "   gh stack merge                       # merge the stack's PRs (interactive)"
echo "   gh stack merge --yes --squash        # merge whole stack, squashing, no prompt"
echo "   gh stack unstack                     # remove current stack (local + GitHub)"
echo "   gh stack alias                       # add short 'gs' alias (gs push, gs view...)"
echo
echo "   Full reference: gh stack --help  /  gh stack <command> --help"
echo "════════════════════════════════════════════════════════"
echo
echo "🐙 Happy coding with GitHub CLI!"
