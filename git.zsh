#!/bin/zsh
# === GitHub SSH + Git Config Setup for macOS Tahoe (Zsh) ===
# Author: theoneandonlywoj
# Description:
#   Generates an SSH key, starts ssh-agent, copies it to clipboard,
#   configures Git user info, ensures macOS keychain integration,
#   and optionally tests the GitHub SSH connection.

key_path="$HOME/.ssh/id_ed25519"
pub_key="$HOME/.ssh/id_ed25519.pub"
ssh_config="$HOME/.ssh/config"

echo "🔧 GitHub SSH + Git Config Setup (macOS Tahoe, Zsh)"
echo "----------------------------------------------------"

# === 1. Check if key already exists ===
if [[ -f "$key_path" ]]; then
  echo "🔑 SSH key already exists at $key_path"
  read "?Do you want to overwrite it? (y/N) "
  overwrite="${REPLY:l}"
  if [[ "$overwrite" != "y" ]]; then
    echo "➡️  Keeping existing key. Skipping key generation."
    skip_gen=true
  else
    echo "🧹 Removing old key..."
    rm -f "$key_path" "$pub_key"
  fi
fi

# === 2. Generate a new SSH key ===
if [[ -z "$skip_gen" ]]; then
  echo "🔧 Generating new SSH key..."
  ssh-keygen -t ed25519 -C "theoneandonlywoj@gmail.com" -f "$key_path" -N "" -q
  if [[ $? -ne 0 ]]; then
    echo "❌ SSH key generation failed."
    exit 1
  fi
fi

# === 3. Start ssh-agent ===
echo "🚀 Starting ssh-agent..."
eval "$(ssh-agent -s)"
if [[ $? -ne 0 ]]; then
  echo "❌ Failed to start ssh-agent."
  exit 1
fi

# === 4. Add the SSH key to the agent and keychain ===
ssh-add --apple-use-keychain "$key_path" 2>/dev/null
if [[ $? -ne 0 ]]; then
  echo "❌ Failed to add SSH key to agent."
  exit 1
else
  echo "✅ SSH key added to macOS keychain."
fi

# === 5. Ensure ~/.ssh/config is configured ===
echo
echo "🛠️  Ensuring SSH config is properly set up..."

mkdir -p "$HOME/.ssh"
touch "$ssh_config"
chmod 600 "$ssh_config"

# Check if the keychain block already exists
if ! grep -q "UseKeychain yes" "$ssh_config" 2>/dev/null; then
  cat <<EOF >> "$ssh_config"

# Added by GitHub SSH setup script
Host *
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519
EOF
  echo "✅ Updated ~/.ssh/config with keychain settings."
else
  echo "ℹ️  ~/.ssh/config already contains keychain setup."
fi

# === 6. Copy the public key to clipboard ===
echo
echo "📋 Copying SSH public key to clipboard..."
if command -v pbcopy >/dev/null 2>&1; then
  cat "$pub_key" | pbcopy
  echo "✅ Key copied to clipboard (pbcopy)."
else
  echo "⚠️  Clipboard utility not found (pbcopy missing)."
fi

# === 7. Display the key as backup ===
echo
echo "Here’s your public key:"
cat "$pub_key"
echo
echo "➡️  Add this key to GitHub:"
echo "   https://github.com/settings/ssh/new"

# === 8. Configure Git user information ===
echo
echo "🧭 Let's configure your Git identity."
read "?Enter your Git user name: " git_name
read "?Enter your Git email: " git_email

if [[ -n "$git_name" ]]; then
  git config --global user.name "$git_name"
fi
if [[ -n "$git_email" ]]; then
  git config --global user.email "$git_email"
fi

# Auto setup remote for new branches
git config --global push.autoSetupRemote true
echo
echo "✅ Git user configuration updated:"
git config --global --list | grep 'user\.'

# === 9. Optional: Test connection ===
echo
read "?Do you want to test your GitHub SSH connection now? (Y/n) "
test_choice="${REPLY:l}"

if [[ -z "$test_choice" || "$test_choice" == "y" ]]; then
  echo
  echo "🔍 Testing connection to GitHub..."
  ssh -T git@github.com
else
  echo "🕒 Skipping connection test. You can run manually later with:"
  echo "   ssh -T git@github.com"
fi

echo
echo "🎉 Setup complete!"
echo "🗝️  SSH key stored at: $key_path"
echo "📂 SSH config: $ssh_config"
echo "🌐 GitHub SSH setup ready to use."
echo "----------------------------------------------------"

