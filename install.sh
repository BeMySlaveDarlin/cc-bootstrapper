#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "cc-bootstrapper: installing (legacy mode)..."

mkdir -p "$CLAUDE_DIR/prompts" "$CLAUDE_DIR/commands"

cp "$REPO_DIR/prompts/meta-prompt-bootstrap.md" "$CLAUDE_DIR/prompts/"
cp -r "$REPO_DIR/prompts/bootstrap" "$CLAUDE_DIR/prompts/"
cp "$REPO_DIR/commands/bootstrap.md" "$CLAUDE_DIR/commands/"

echo "cc-bootstrapper: installed"
echo "  prompts  → $CLAUDE_DIR/prompts/meta-prompt-bootstrap.md"
echo "  command  → $CLAUDE_DIR/commands/bootstrap.md"
echo ""
echo "Usage: claude → /bootstrap"
