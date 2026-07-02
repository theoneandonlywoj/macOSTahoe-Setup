# === Makefile for config sync (macOS Tahoe) ===
# Syncs Doom Emacs, tmux, OpenCode commands, and Claude skills between this repo and $HOME
# Moves existing configs to timestamped backups before installing new ones
# Supports restore from the most recent backup

.PHONY: all doom-sync doom-backup doom-restore doom-diff \
        tmux-sync tmux-backup tmux-restore tmux-diff \
        sync backup restore diff tsync tbackup trestore tdiff \
        opencode-sync opencode-backup opencode-restore opencode-diff \
        claude-sync claude-backup claude-restore claude-diff \
        skills-sync osync obackup orestore odiff csync cbackup crestore cdiff ssync \
        soft-test reload-shell help

# Generate timestamp in format YYYY_mm_dd_hh_MM
TIMESTAMP := $(shell date +"%Y_%m_%d_%H_%M")

# Doom Emacs paths
DOOM_BACKUP_DIR := $(HOME)/.doom.d_backup_$(TIMESTAMP)
DOOM_REPO_DIR := ./.doom.d

# tmux paths
TMUX_BACKUP_FILE := $(HOME)/.tmux.conf.backup_$(TIMESTAMP)
TMUX_REPO_FILE := ./tmux.conf

# OpenCode (commands) paths — scoped to the commands/ subdir only
OPENCODE_REPO_CMDS  := ./.config/opencode/commands
OPENCODE_HOME_CMDS  := $(HOME)/.config/opencode/commands
OPENCODE_BACKUP_DIR := $(HOME)/.config/opencode/commands_backup_$(TIMESTAMP)

# Claude (skills) paths — scoped to the skills/ subdir only
CLAUDE_REPO_SKILLS  := ./.claude/skills
CLAUDE_HOME_SKILLS  := $(HOME)/.claude/skills
CLAUDE_BACKUP_DIR   := $(HOME)/.claude/skills_backup_$(TIMESTAMP)

# ============================================================
# DEFAULT TARGET
# ============================================================

all: doom-sync
	@echo "✅ Doom Emacs configuration synced!"

# ============================================================
# DOOM EMACS CONFIGURATION
# ============================================================

doom-sync: doom-backup
	@echo "📦 Copying new Doom Emacs configuration..."
	@cp -r $(DOOM_REPO_DIR) $(HOME)/.doom.d
	@if command -v doom >/dev/null 2>&1; then \
		echo "🔄 Running doom sync..."; \
		doom sync; \
	else \
		echo "⚠️  doom command not found in PATH"; \
		echo "💡 Run: source ~/.zshrc && doom sync"; \
	fi
	@echo "✅ New configuration synced to $(HOME)/.doom.d"

doom-backup:
	@if [ -d "$(HOME)/.doom.d" ]; then \
		echo "💾 Backing up existing ~/.doom.d to $(DOOM_BACKUP_DIR)..."; \
		mv "$(HOME)/.doom.d" "$(DOOM_BACKUP_DIR)"; \
		echo "✅ Backup created at $(DOOM_BACKUP_DIR)"; \
	else \
		echo "ℹ️  No existing ~/.doom.d found — skipping backup."; \
	fi

doom-restore:
	@echo "♻️  Restoring the most recent Doom Emacs backup..."
	@latest_backup=$$(ls -d $(HOME)/.doom.d_backup_* 2>/dev/null | sort -r | head -n 1); \
	if [ -z "$$latest_backup" ]; then \
		echo "❌ No backups found. Cannot restore."; \
		exit 1; \
	fi; \
	if [ -d "$(HOME)/.doom.d" ]; then \
		echo "🗑  Removing current ~/.doom.d before restore..."; \
		rm -rf "$(HOME)/.doom.d"; \
	fi; \
	echo "♻️  Restoring from $$latest_backup..."; \
	mv "$$latest_backup" "$(HOME)/.doom.d"; \
	echo "✅ Restore complete from $$latest_backup"; \
	if command -v doom >/dev/null 2>&1; then \
		echo "🔄 Running doom sync..."; \
		doom sync; \
	fi

doom-diff:
	@echo "📊 Comparing Doom Emacs configurations..."
	@echo
	@echo "=== config.el ==="
	@diff -u "$(HOME)/.doom.d/config.el" "$(DOOM_REPO_DIR)/config.el" 2>/dev/null || echo "(files differ or missing)"
	@echo
	@echo "=== init.el ==="
	@diff -u "$(HOME)/.doom.d/init.el" "$(DOOM_REPO_DIR)/init.el" 2>/dev/null || echo "(files differ or missing)"
	@echo
	@echo "=== packages.el ==="
	@diff -u "$(HOME)/.doom.d/packages.el" "$(DOOM_REPO_DIR)/packages.el" 2>/dev/null || echo "(files differ or missing)"

# ============================================================
# TMUX CONFIGURATION
# ============================================================

tmux-sync: tmux-backup
	@echo "📦 Copying new tmux configuration..."
	@cp $(TMUX_REPO_FILE) $(HOME)/.tmux.conf
	@if command -v tmux >/dev/null 2>&1 && [ -n "$$TMUX" ]; then \
		echo "🔄 Reloading tmux config..."; \
		tmux source-file $(HOME)/.tmux.conf >/dev/null 2>&1 || true; \
	fi
	@echo "✅ New configuration synced to $(HOME)/.tmux.conf"

tmux-backup:
	@if [ -f "$(HOME)/.tmux.conf" ]; then \
		echo "💾 Backing up existing ~/.tmux.conf to $(TMUX_BACKUP_FILE)..."; \
		cp "$(HOME)/.tmux.conf" "$(TMUX_BACKUP_FILE)"; \
		echo "✅ Backup created at $(TMUX_BACKUP_FILE)"; \
	else \
		echo "ℹ️  No existing ~/.tmux.conf found — skipping backup."; \
	fi

tmux-restore:
	@echo "♻️  Restoring the most recent tmux backup..."
	@latest_backup=$$(ls -t $(HOME)/.tmux.conf.backup_* 2>/dev/null | head -n 1); \
	if [ -z "$$latest_backup" ]; then \
		echo "❌ No backups found. Cannot restore."; \
		exit 1; \
	fi; \
	echo "♻️  Restoring from $$latest_backup..."; \
	cp "$$latest_backup" "$(HOME)/.tmux.conf"; \
	echo "✅ Restore complete from $$latest_backup"; \
	if command -v tmux >/dev/null 2>&1 && [ -n "$$TMUX" ]; then \
		echo "🔄 Reloading tmux config..."; \
		tmux source-file $(HOME)/.tmux.conf >/dev/null 2>&1 || true; \
	fi

tmux-diff:
	@echo "📊 Comparing tmux configurations..."
	@diff -u "$(HOME)/.tmux.conf" "$(TMUX_REPO_FILE)" 2>/dev/null || echo "(files differ or missing)"

# ============================================================
# OPENCODE COMMANDS
# ============================================================

opencode-sync: opencode-backup
	@echo "📦 Copying new OpenCode commands..."
	@mkdir -p $(HOME)/.config/opencode
	@cp -r $(OPENCODE_REPO_CMDS) $(OPENCODE_HOME_CMDS)
	@echo "✅ New commands synced to $(OPENCODE_HOME_CMDS)"

opencode-backup:
	@if [ -d "$(OPENCODE_HOME_CMDS)" ]; then \
		echo "💾 Backing up existing $(OPENCODE_HOME_CMDS) to $(OPENCODE_BACKUP_DIR)..."; \
		mv "$(OPENCODE_HOME_CMDS)" "$(OPENCODE_BACKUP_DIR)"; \
		echo "✅ Backup created at $(OPENCODE_BACKUP_DIR)"; \
	else \
		echo "ℹ️  No existing $(OPENCODE_HOME_CMDS) found — skipping backup."; \
	fi

opencode-restore:
	@echo "♻️  Restoring the most recent OpenCode commands backup..."
	@latest_backup=$$(ls -d $(HOME)/.config/opencode/commands_backup_* 2>/dev/null | sort -r | head -n 1); \
	if [ -z "$$latest_backup" ]; then \
		echo "❌ No backups found. Cannot restore."; \
		exit 1; \
	fi; \
	if [ -d "$(OPENCODE_HOME_CMDS)" ]; then \
		echo "🗑  Removing current $(OPENCODE_HOME_CMDS) before restore..."; \
		rm -rf "$(OPENCODE_HOME_CMDS)"; \
	fi; \
	echo "♻️  Restoring from $$latest_backup..."; \
	mv "$$latest_backup" "$(OPENCODE_HOME_CMDS)"; \
	echo "✅ Restore complete from $$latest_backup"

opencode-diff:
	@echo "📊 Comparing OpenCode commands..."
	@diff -ru "$(OPENCODE_HOME_CMDS)" "$(OPENCODE_REPO_CMDS)" 2>/dev/null || echo "(files differ or missing)"

# ============================================================
# CLAUDE SKILLS
# ============================================================

claude-sync: claude-backup
	@echo "📦 Copying new Claude skills..."
	@mkdir -p $(HOME)/.claude
	@cp -r $(CLAUDE_REPO_SKILLS) $(CLAUDE_HOME_SKILLS)
	@echo "✅ New skills synced to $(CLAUDE_HOME_SKILLS)"

claude-backup:
	@if [ -d "$(CLAUDE_HOME_SKILLS)" ]; then \
		echo "💾 Backing up existing $(CLAUDE_HOME_SKILLS) to $(CLAUDE_BACKUP_DIR)..."; \
		mv "$(CLAUDE_HOME_SKILLS)" "$(CLAUDE_BACKUP_DIR)"; \
		echo "✅ Backup created at $(CLAUDE_BACKUP_DIR)"; \
	else \
		echo "ℹ️  No existing $(CLAUDE_HOME_SKILLS) found — skipping backup."; \
	fi

claude-restore:
	@echo "♻️  Restoring the most recent Claude skills backup..."
	@latest_backup=$$(ls -d $(HOME)/.claude/skills_backup_* 2>/dev/null | sort -r | head -n 1); \
	if [ -z "$$latest_backup" ]; then \
		echo "❌ No backups found. Cannot restore."; \
		exit 1; \
	fi; \
	if [ -d "$(CLAUDE_HOME_SKILLS)" ]; then \
		echo "🗑  Removing current $(CLAUDE_HOME_SKILLS) before restore..."; \
		rm -rf "$(CLAUDE_HOME_SKILLS)"; \
	fi; \
	echo "♻️  Restoring from $$latest_backup..."; \
	mv "$$latest_backup" "$(CLAUDE_HOME_SKILLS)"; \
	echo "✅ Restore complete from $$latest_backup"

claude-diff:
	@echo "📊 Comparing Claude skills..."
	@diff -ru "$(CLAUDE_HOME_SKILLS)" "$(CLAUDE_REPO_SKILLS)" 2>/dev/null || echo "(files differ or missing)"

# ============================================================
# COMBINED SKILLS SYNC
# ============================================================

skills-sync: opencode-sync claude-sync
	@echo "✅ All AI coding skills synced (OpenCode commands + Claude skills)"

# ============================================================
# CONVENIENCE ALIASES
# ============================================================

sync: doom-sync

backup: doom-backup

restore: doom-restore

diff: doom-diff

tsync: tmux-sync

tbackup: tmux-backup

trestore: tmux-restore

tdiff: tmux-diff

osync: opencode-sync

obackup: opencode-backup

orestore: opencode-restore

odiff: opencode-diff

csync: claude-sync

cbackup: claude-backup

crestore: claude-restore

cdiff: claude-diff

ssync: skills-sync

# ============================================================
# TESTING
# ============================================================

soft-test:
	@echo "🧪 Local Testing for macOS Tahoe Setup Scripts"
	@echo "==============================================="
	@echo
	@failed_count=0; \
	total_count=0; \
	\
	# Test 1: Check if all .zsh scripts have shebang \
	echo "📋 Step 1: Checking shebang lines..."; \
	echo "-----------------------------------"; \
	for script in *.zsh; do \
		if [ -f "$$script" ]; then \
			total_count=$$((total_count + 1)); \
			if head -n 1 "$$script" | grep -q '#!/bin/zsh\|#!/usr/bin/env zsh'; then \
				echo "✅ $$script"; \
			else \
				echo "❌ $$script - Missing shebang line"; \
				failed_count=$$((failed_count + 1)); \
			fi; \
		fi; \
	done; \
	echo; \
	\
	# Test 2: Check Zsh syntax \
	echo "📋 Step 2: Validating Zsh syntax..."; \
	echo "-----------------------------------"; \
	for script in *.zsh; do \
		if [ -f "$$script" ]; then \
			echo -n "Checking $$script... "; \
			if zsh -n "$$script" 2>/dev/null; then \
				echo "✅"; \
			else \
				echo "❌"; \
				zsh -n "$$script" 2>&1 || true; \
				failed_count=$$((failed_count + 1)); \
			fi; \
		fi; \
	done; \
	echo; \
	\
	# Test 3: Check executability \
	echo "📋 Step 3: Checking file permissions..."; \
	echo "-----------------------------------"; \
	for script in *.zsh; do \
		if [ -f "$$script" ]; then \
			if [ -x "$$script" ]; then \
				echo "✅ $$script is executable"; \
			else \
				echo "⚠️  $$script is not executable"; \
				chmod +x "$$script"; \
				echo "   → Made executable"; \
			fi; \
		fi; \
	done; \
	echo; \
	\
	# Test 4: Check for required structure \
	echo "📋 Step 4: Checking script structure..."; \
	echo "-----------------------------------"; \
	for script in *.zsh; do \
		if [ -f "$$script" ]; then \
			has_purpose_or_desc=false; \
			has_author=false; \
			has_echo=false; \
			if grep -q "Purpose:" "$$script" 2>/dev/null || grep -q "Description:" "$$script" 2>/dev/null; then \
				has_purpose_or_desc=true; \
			fi; \
			if grep -q "Author:" "$$script" 2>/dev/null; then \
				has_author=true; \
			fi; \
			if grep -q "echo" "$$script" 2>/dev/null; then \
				has_echo=true; \
			fi; \
			if [ "$$has_purpose_or_desc" = true ] && [ "$$has_author" = true ] && [ "$$has_echo" = true ]; then \
				echo "✅ $$script has proper structure"; \
			else \
				echo "⚠️  $$script - Missing some structure elements"; \
				if [ "$$has_purpose_or_desc" = false ]; then \
					echo "   → Missing Purpose/Description"; \
				fi; \
				if [ "$$has_author" = false ]; then \
					echo "   → Missing Author"; \
				fi; \
				if [ "$$has_echo" = false ]; then \
					echo "   → Missing echo statements"; \
				fi; \
			fi; \
		fi; \
	done; \
	echo; \
	\
	# Test 5: Check Doom config files \
	echo "📋 Step 5: Checking Doom Emacs config..."; \
	echo "-----------------------------------"; \
	if [ -d "$(DOOM_REPO_DIR)" ]; then \
		echo "✅ .doom.d directory exists"; \
		for config in config.el init.el packages.el; do \
			if [ -f "$(DOOM_REPO_DIR)/$$config" ]; then \
				echo "✅ $$config found"; \
			else \
				echo "❌ $$config missing"; \
				failed_count=$$((failed_count + 1)); \
			fi; \
		done; \
	else \
		echo "❌ .doom.d directory not found"; \
		failed_count=$$((failed_count + 1)); \
	fi; \
	echo; \
	\
	# Test 6: Check tmux config file \
	echo "📋 Step 6: Checking tmux config..."; \
	echo "-----------------------------------"; \
	if [ -f "$(TMUX_REPO_FILE)" ]; then \
		echo "✅ tmux.conf found"; \
	else \
		echo "❌ tmux.conf missing"; \
		failed_count=$$((failed_count + 1)); \
	fi; \
	echo; \
	\
	# Summary \
	echo "==============================================="; \
	echo "📊 Testing Summary"; \
	echo "==============================================="; \
	passed=$$((total_count - failed_count)); \
	echo "Total scripts: $$total_count"; \
	echo "Passed: $$passed"; \
	echo "Failed: $$failed_count"; \
	if [ $$failed_count -eq 0 ]; then \
		echo; \
		echo "🎉 All tests passed!"; \
		echo "✅ You can safely push to GitHub"; \
		exit 0; \
	else \
		echo; \
		echo "⚠️  Some tests failed"; \
		echo "💡 Fix the issues above before pushing"; \
		exit 1; \
	fi

# ============================================================
# SHELL
# ============================================================

reload-shell:
	@echo "🔄 Reloading shell configuration..."
	@exec $$SHELL -l

# ============================================================
# HELP
# ============================================================

help:
	@echo "╔══════════════════════════════════════════════════════════════╗"
	@echo "║          macOS Tahoe Setup — Makefile Commands               ║"
	@echo "╚══════════════════════════════════════════════════════════════╝"
	@echo
	@echo "DEFAULT"
	@echo "  make / make all       Sync Doom Emacs config (back up existing"
	@echo "                        ~/.doom.d, copy repo config, run doom sync)"
	@echo
	@echo "DOOM EMACS"
	@echo "  make doom-sync        Back up existing config, then copy .doom.d"
	@echo "                        from repo to ~/.doom.d and run doom sync"
	@echo "  make doom-backup      Move existing ~/.doom.d to a timestamped"
	@echo "                        backup directory (~/.doom.d_backup_YYYY_MM_DD_HH_MM)"
	@echo "  make doom-restore     Restore the most recent backup by moving it"
	@echo "                        back to ~/.doom.d (deletes current config first)"
	@echo "  make doom-diff        Diff the three core Doom config files"
	@echo "                        (config.el, init.el, packages.el) between"
	@echo "                        the installed ~/.doom.d and the repo copy"
	@echo
	@echo "TMUX"
	@echo "  make tmux-sync        Back up existing config, then copy tmux.conf"
	@echo "                        from repo to ~/.tmux.conf and reload if in tmux"
	@echo "  make tmux-backup      Copy existing ~/.tmux.conf to a timestamped"
	@echo "                        backup (~/.tmux.conf.backup_YYYY_MM_DD_HH_MM)"
	@echo "  make tmux-restore     Restore the most recent tmux backup"
	@echo "                        (reloads config if inside a tmux session)"
	@echo "  make tmux-diff        Diff the installed ~/.tmux.conf vs repo copy"
	@echo
	@echo "OPENCODE COMMANDS"
	@echo "  make opencode-sync    Back up existing ~/.config/opencode/commands, then"
	@echo "                        copy repo commands there (repo is source of truth)"
	@echo "  make opencode-backup  Move existing commands to a timestamped"
	@echo "                        backup (~/.config/opencode/commands_backup_YYYY_MM_DD_HH_MM)"
	@echo "  make opencode-restore Restore the most recent commands backup"
	@echo "                        (deletes current commands first)"
	@echo "  make opencode-diff    Diff installed vs repo OpenCode commands (recursive)"
	@echo
	@echo "CLAUDE SKILLS"
	@echo "  make claude-sync      Back up existing ~/.claude/skills, then copy repo"
	@echo "                        skills there (repo is source of truth). Moves the"
	@echo "                        entire skills dir, so all skills must live in the repo"
	@echo "                        (commit, pr, graphify, create-skill) to survive sync."
	@echo "  make claude-backup    Move existing skills to a timestamped"
	@echo "                        backup (~/.claude/skills_backup_YYYY_MM_DD_HH_MM)"
	@echo "  make claude-restore   Restore the most recent skills backup"
	@echo "                        (deletes current skills first)"
	@echo "  make claude-diff      Diff installed vs repo Claude skills (recursive)"
	@echo
	@echo "COMBINED"
	@echo "  make skills-sync      Run opencode-sync + claude-sync in one go"
	@echo
	@echo "SHORTCUTS"
	@echo "  make sync             Alias for doom-sync"
	@echo "  make backup           Alias for doom-backup"
	@echo "  make restore          Alias for doom-restore"
	@echo "  make diff             Alias for doom-diff"
	@echo "  make tsync            Alias for tmux-sync"
	@echo "  make tbackup          Alias for tmux-backup"
	@echo "  make trestore         Alias for tmux-restore"
	@echo "  make tdiff            Alias for tmux-diff"
	@echo "  make osync            Alias for opencode-sync"
	@echo "  make obackup          Alias for opencode-backup"
	@echo "  make orestore         Alias for opencode-restore"
	@echo "  make odiff            Alias for opencode-diff"
	@echo "  make csync            Alias for claude-sync"
	@echo "  make cbackup          Alias for claude-backup"
	@echo "  make crestore         Alias for claude-restore"
	@echo "  make cdiff            Alias for claude-diff"
	@echo "  make ssync            Alias for skills-sync"
	@echo
	@echo "TESTING"
	@echo "  make soft-test        Validate all .zsh scripts in the repo:"
	@echo "                        shebang lines, Zsh syntax, file permissions,"
	@echo "                        script structure (Purpose, Author, echo),"
	@echo "                        and Doom/tmux config file presence"
	@echo
	@echo "SHELL"
	@echo "  make reload-shell     Reload shell (restart with .zshrc)"
	@echo
	@echo "HELP"
	@echo "  make help             Show this help message"
	@echo
	@echo "See docs/makefile-commands.md for full documentation."
