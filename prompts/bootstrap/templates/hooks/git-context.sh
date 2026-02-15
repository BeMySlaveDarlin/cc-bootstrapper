#!/bin/bash
set -uo pipefail
ERR_LOG="${CLAUDE_PROJECT_DIR:-.}/.claude/state/.hook-errors.log"
trap 'echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] ERROR in $(basename "$0"):$LINENO" >> "$ERR_LOG" 2>/dev/null; exit 0' ERR

PROJECT_DIR="$CLAUDE_PROJECT_DIR"
STATE_DIR="$PROJECT_DIR/.claude/state"
CONTEXT_FILE="$STATE_DIR/.git-context.md"

cd "$PROJECT_DIR" || exit 0

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    exit 0
fi

BRANCH=$(git branch --show-current 2>/dev/null || echo "detached")
LAST_COMMITS=$(git log --oneline -5 2>/dev/null || echo "—")
UNCOMMITTED=$(git diff --stat 2>/dev/null || echo "—")
STAGED=$(git diff --cached --stat 2>/dev/null || echo "—")
UNTRACKED=$(git ls-files --others --exclude-standard 2>/dev/null | head -10)

cat > "$CONTEXT_FILE" << EOF
# Git Context

**Branch:** $BRANCH
**Generated:** $(date -u +"%Y-%m-%dT%H:%M:%SZ")

## Last 5 Commits

$LAST_COMMITS

## Uncommitted Changes

$UNCOMMITTED

## Staged

$STAGED

## Untracked (top 10)

$UNTRACKED
EOF

exit 0
