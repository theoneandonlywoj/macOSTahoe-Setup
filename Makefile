# === Makefile for OpenClaw macOS Setup ===
# Runs the OpenClaw setup script for Mac Mini configuration

.PHONY: all setup help

# ============================================================
# DEFAULT TARGET
# ============================================================

all: setup

# ============================================================
# SETUP
# ============================================================

setup:
	@echo "🦞 Running OpenClaw macOS Setup..."
	@chmod +x openclaw_setup.zsh
	@./openclaw_setup.zsh

# ============================================================
# HELP
# ============================================================

help:
	@echo "OpenClaw macOS Setup - Available Targets"
	@echo "========================================="
	@echo
	@echo "SETUP:"
	@echo "  make              Run the OpenClaw setup script (default)"
	@echo "  make setup        Run the OpenClaw setup script"
	@echo
	@echo "HELP:"
	@echo "  make help         Show this help message"
