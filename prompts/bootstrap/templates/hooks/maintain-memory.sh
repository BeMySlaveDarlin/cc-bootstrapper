#!/bin/bash
set -uo pipefail
ERR_LOG="${CLAUDE_PROJECT_DIR:-.}/.claude/memory/.hook-errors.log"
trap 'echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] ERROR in $(basename "$0"):$LINENO" >> "$ERR_LOG" 2>/dev/null; exit 0' ERR

MEMORY_DIR="$CLAUDE_PROJECT_DIR/.claude/memory"
DECISIONS_DIR="$MEMORY_DIR/decisions"
ARCHIVE_DIR="$DECISIONS_DIR/archive"
SESSIONS_DIR="$MEMORY_DIR/sessions"
LOG_FILE="$MEMORY_DIR/usage.jsonl"

ARCHIVE_DAYS=${MEMORY_ARCHIVE_DAYS:-30}
MAX_DECISIONS=${MEMORY_MAX_DECISIONS:-20}
MAX_LOG_LINES=${MEMORY_MAX_LOG_LINES:-500}
SESSION_RETENTION_DAYS=${MEMORY_SESSION_DAYS:-60}

mkdir -p "$ARCHIVE_DIR"

find "$DECISIONS_DIR" -maxdepth 1 -name "*.md" -mtime +$ARCHIVE_DAYS -exec mv {} "$ARCHIVE_DIR/" \; 2>/dev/null

DECISION_COUNT=$(find "$DECISIONS_DIR" -maxdepth 1 -name "*.md" 2>/dev/null | wc -l)
if [ "$DECISION_COUNT" -gt "$MAX_DECISIONS" ]; then
    EXCESS=$(( DECISION_COUNT - MAX_DECISIONS ))
    ls -t "$DECISIONS_DIR"/*.md 2>/dev/null | tail -n "$EXCESS" | while read -r f; do
        mv "$f" "$ARCHIVE_DIR/" 2>/dev/null
    done
fi

if [ -f "$LOG_FILE" ]; then
    LINE_COUNT=$(wc -l < "$LOG_FILE")
    if [ "$LINE_COUNT" -gt "$MAX_LOG_LINES" ]; then
        tail -n "$MAX_LOG_LINES" "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
    fi
fi

if [ -d "$SESSIONS_DIR" ]; then
    find "$SESSIONS_DIR" -maxdepth 1 -name "*.md" -mtime +$SESSION_RETENTION_DAYS -delete 2>/dev/null
fi

exit 0
