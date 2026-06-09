#!/bin/zsh
# === graphify.zsh ===
# Purpose: Install Graphify (AI knowledge-graph CLI & skill) on macOS Tahoe
# Shell: Zsh (default on macOS Tahoe)
# Author: theoneandonlywoj

echo "📊 Starting installation of Graphify on macOS Tahoe..."
echo

# === Configuration ===
# Graphify ships on PyPI as "graphifyy" (double-y), but the CLI command is "graphify".
# It is installed as a uv-managed tool, so its binary lives in uv's tool bin directory.
pypi_package="graphifyy"
cli_command="graphify"

echo "📦 PyPI package:       $pypi_package"
echo "🔧 CLI command:        $cli_command"
echo

# === 1. Check if Graphify is already installed ===
if command -v "$cli_command" >/dev/null 2>&1; then
  current_version=$("$cli_command" --version 2>/dev/null | head -n 1 || echo "unknown")
  echo "✅ Graphify is already installed ($current_version)"
  echo
  echo "💡 To update, run: uv tool upgrade $pypi_package"
  echo "🎉 Nothing to do!"
  exit 0
fi

# === 2. Ensure Homebrew is installed ===
if ! command -v brew >/dev/null 2>&1; then
  echo "⚙️  Homebrew not found. Installing..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ -d "/opt/homebrew/bin" ]]; then
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
  echo "✅ Homebrew installed."
  echo
fi

# === 3. Ensure uv is installed ===
# uv provisions its own managed Python (3.10+ required by Graphify), so we don't
# need to install Python separately here.
if command -v uv >/dev/null 2>&1; then
  echo "✅ uv is already available."
else
  echo "📥 Installing uv via Homebrew..."
  brew install uv
  if [[ $? -ne 0 ]]; then
    echo "❌ Failed to install uv via Homebrew."
    echo "⚠️  Try running manually: brew install uv"
    exit 1
  fi
  echo "✅ uv installed."
fi
echo

# === 4. Install Graphify via uv ===
echo "📥 Installing Graphify ($pypi_package) via uv..."
uv tool install "$pypi_package"
if [[ $? -ne 0 ]]; then
  echo "❌ Graphify installation failed."
  echo "⚠️  Try running manually: uv tool install $pypi_package"
  echo "   Alternatively: pipx install $pypi_package"
  exit 1
fi
echo "✅ Graphify installed via uv."
echo

# === 5. Register the Graphify skill with your AI assistant ===
# This enables the /graphify skill in Claude Code and other compatible assistants.
echo "🔗 Registering the Graphify skill (graphify install)..."
"$cli_command" install
if [[ $? -ne 0 ]]; then
  echo "⚠️  Skill registration did not complete cleanly."
  echo "   You can retry later with: $cli_command install"
else
  echo "✅ Graphify skill registered."
fi
echo

# === 6. Verify installation ===
echo "🧪 Verifying installation..."
echo

if command -v "$cli_command" >/dev/null 2>&1; then
  installed_version=$("$cli_command" --version 2>/dev/null | head -n 1 || echo "unknown")
  echo "✅ Graphify: installed ($installed_version)"
else
  echo "⚠️  '$cli_command' not found on your PATH."
  echo "   uv installs tools to ~/.local/bin — make sure it's on your PATH:"
  echo "      uv tool update-shell"
  echo "   Then restart your shell (or run: exec zsh)."
  exit 1
fi

echo
echo "🎉 Graphify installation complete!"
echo

# === 7. How to use Graphify ===
echo "💡 How to use Graphify:"
echo
echo "   📈 Build a knowledge graph from the current folder:"
echo "        $cli_command ."
echo "      → outputs land in ./graphify-out/:"
echo "          • graph.html        — interactive browser visualization"
echo "          • GRAPH_REPORT.md   — key concepts and insights"
echo "          • graph.json        — queryable graph data"
echo
echo "   🔎 Ask questions about your graph:"
echo "        $cli_command query \"what connects auth to the database?\""
echo
echo "   🤖 Inside Claude Code (after registration), just run:"
echo "        /graphify ."
echo
echo "   🔑 For headless / CI extraction of docs, PDFs or images, set a backend key:"
echo "        export ANTHROPIC_API_KEY=...   # Claude"
echo "        export GEMINI_API_KEY=...      # Google Gemini"
echo "        export OPENAI_API_KEY=...      # OpenAI"
echo "      (Code-only extraction needs no API key.)"
echo
echo "   ⬆️  Update later with: uv tool upgrade $pypi_package"
echo "   📚 Docs: https://github.com/safishamsi/graphify"
echo
echo "✨ Happy graphing!"
