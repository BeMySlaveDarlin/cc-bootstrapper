#!/bin/bash
set -uo pipefail
ERR_LOG="${CLAUDE_PROJECT_DIR:-.}/.claude/state/.hook-errors.log"
trap 'echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] ERROR in $(basename "$0"):$LINENO" >> "$ERR_LOG" 2>/dev/null; exit 0' ERR

PROJECT_DIR="$CLAUDE_PROJECT_DIR"
STATE_DIR="$PROJECT_DIR/.claude/state"
FACTS_FILE="$STATE_DIR/facts.md"
DECISIONS_DIR="$STATE_DIR/decisions"
ARCHIVE_DIR="$DECISIONS_DIR/archive"
MEMORY_DIR="$STATE_DIR/memory"
SESSIONS_DIR="$STATE_DIR/sessions"
SESSIONS_ARCHIVE="$SESSIONS_DIR/archive"
LOG_FILE="$STATE_DIR/usage.jsonl"

mkdir -p "$DECISIONS_DIR" "$ARCHIVE_DIR" "$MEMORY_DIR" "$SESSIONS_ARCHIVE"

if [ ! -f "$FACTS_FILE" ]; then
    cat > "$FACTS_FILE" << 'FACTSEOF'
# Project Facts

## Stack
—

## Key Paths
—

## Active Decisions
—

## Known Issues
—

## Last Updated
—
FACTSEOF
fi

if [ ! -f "$MEMORY_DIR/patterns.md" ]; then
    printf '# Code Patterns\n\n—\n' > "$MEMORY_DIR/patterns.md"
fi

if [ ! -f "$MEMORY_DIR/issues.md" ]; then
    printf '# Known Issues\n\n| Date | Issue | Frequency | Resolution |\n|------|-------|-----------|------------|\n' > "$MEMORY_DIR/issues.md"
fi

ARCHIVE_DAYS=${MEMORY_ARCHIVE_DAYS:-30}
find "$DECISIONS_DIR" -maxdepth 1 -name "*.md" -mtime +$ARCHIVE_DAYS -exec mv {} "$ARCHIVE_DIR/" \; 2>/dev/null

DECISION_COUNT=$(find "$DECISIONS_DIR" -maxdepth 1 -name "*.md" 2>/dev/null | wc -l)
if [ "$DECISION_COUNT" -gt 20 ]; then
    OLDEST=$(find "$DECISIONS_DIR" -maxdepth 1 -name "*.md" -printf '%T+ %p\n' 2>/dev/null | sort | head -5 | awk '{print $2}')
    for f in $OLDEST; do
        mv "$f" "$ARCHIVE_DIR/" 2>/dev/null
    done
fi

if [ -f "$LOG_FILE" ]; then
    CUTOFF=$(date -d '90 days ago' +%Y-%m-%dT%H:%M:%S 2>/dev/null || date -v-90d +%Y-%m-%dT%H:%M:%S 2>/dev/null)
    if [ -n "$CUTOFF" ]; then
        jq -c "select(.timestamp > \"$CUTOFF\")" "$LOG_FILE" > "$LOG_FILE.tmp" 2>/dev/null && mv "$LOG_FILE.tmp" "$LOG_FILE"
    fi
fi

find "$SESSIONS_DIR" -maxdepth 1 -name "*-session.md" -mtime +60 -exec mv {} "$SESSIONS_ARCHIVE/" \; 2>/dev/null

exit 0
