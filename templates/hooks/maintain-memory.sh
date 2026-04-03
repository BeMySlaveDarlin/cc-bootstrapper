#!/bin/bash
set -uo pipefail

[ -z "${CLAUDE_PROJECT_DIR:-}" ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0

ERR_LOG="${CLAUDE_PROJECT_DIR}/.claude/memory/.hook-errors.log"
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

# --- facts.md: dead decision links ---
FACTS_FILE="$MEMORY_DIR/facts.md"
if [ -f "$FACTS_FILE" ] && [ -d "$DECISIONS_DIR" ]; then
    TEMP_FACTS=$(mktemp)
    while IFS= read -r line; do
        if echo "$line" | grep -q 'decisions/.*\.md' 2>/dev/null; then
            REF=$(echo "$line" | grep -oP 'decisions/[^\s\)]+\.md')
            if [ -n "$REF" ] && [ ! -f "$MEMORY_DIR/$REF" ]; then
                continue
            fi
        fi
        echo "$line" >> "$TEMP_FACTS"
    done < "$FACTS_FILE"
    mv "$TEMP_FACTS" "$FACTS_FILE"
fi

# --- issues.md: compaction ---
MAX_ISSUES=${MEMORY_MAX_ISSUES:-30}
ISSUES_FILE="$MEMORY_DIR/issues.md"
if [ -f "$ISSUES_FILE" ]; then
    ROW_COUNT=$(grep -c '^|[^-]' "$ISSUES_FILE" 2>/dev/null || echo 0)
    ROW_COUNT=$((ROW_COUNT - 1))
    if [ "$ROW_COUNT" -gt "$MAX_ISSUES" ]; then
        HEAD_LINES=$(grep -n '^|' "$ISSUES_FILE" | head -2 | tail -1 | cut -d: -f1)
        { head -n "$HEAD_LINES" "$ISSUES_FILE"; grep '^|[^-]' "$ISSUES_FILE" | tail -n +2 | head -n "$MAX_ISSUES"; } > "$ISSUES_FILE.tmp"
        mv "$ISSUES_FILE.tmp" "$ISSUES_FILE"
    fi
fi

# --- output: cleanup old plans/reviews (>7 days) ---
for subdir in plans reviews; do
    if [ -d "$CLAUDE_PROJECT_DIR/.claude/output/$subdir" ]; then
        find "$CLAUDE_PROJECT_DIR/.claude/output/$subdir" -name "*.md" -mtime +7 -delete 2>/dev/null
    fi
done

exit 0
