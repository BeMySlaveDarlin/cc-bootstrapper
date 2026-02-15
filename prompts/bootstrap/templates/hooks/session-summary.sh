#!/bin/bash
set -uo pipefail
ERR_LOG="${CLAUDE_PROJECT_DIR:-.}/.claude/state/.hook-errors.log"
trap 'echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] ERROR in $(basename "$0"):$LINENO" >> "$ERR_LOG" 2>/dev/null; exit 0' ERR

LOG_DIR="$CLAUDE_PROJECT_DIR/.claude/state"
LOG_FILE="$LOG_DIR/usage.jsonl"
SESSIONS_DIR="$LOG_DIR/sessions"
mkdir -p "$SESSIONS_DIR"

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')

if [ ! -f "$LOG_FILE" ]; then
    exit 0
fi

SESSION_ENTRIES=$(jq -c "select(.session_id == \"$SESSION_ID\")" "$LOG_FILE" 2>/dev/null)
ENTRY_COUNT=$(echo "$SESSION_ENTRIES" | jq -s 'length' 2>/dev/null)

if [ "$ENTRY_COUNT" -eq 0 ]; then
    exit 0
fi

TIMESTAMP=$(date +"%Y-%m-%d-%H%M%S")
BRANCH=$(echo "$SESSION_ENTRIES" | jq -r -s 'last.branch // "unknown"')
SUMMARY_FILE="$SESSIONS_DIR/${TIMESTAMP}-${BRANCH}-session.md"

TOTAL_IN=$(echo "$SESSION_ENTRIES" | jq -s '[.[].input_chars] | add // 0')
TOTAL_OUT=$(echo "$SESSION_ENTRIES" | jq -s '[.[].output_chars] | add // 0')

AGENTS_BREAKDOWN=$(echo "$SESSION_ENTRIES" | jq -s '
    group_by(.agent) | map({
        agent: .[0].agent,
        calls: length,
        input_chars: [.[].input_chars] | add,
        output_chars: [.[].output_chars] | add
    }) | sort_by(-.calls)
')

cat > "$SUMMARY_FILE" << EOF
# Session Summary

**Date:** $(date +"%Y-%m-%d %H:%M")
**Session ID:** $SESSION_ID
**Branch:** $BRANCH

## Totals

| Metric | Value |
|--------|-------|
| Agent calls | $ENTRY_COUNT |
| Input chars | $TOTAL_IN |
| Output chars | $TOTAL_OUT |

## By Agent

| Agent | Calls | Input chars | Output chars |
|-------|-------|-------------|--------------|
EOF

echo "$AGENTS_BREAKDOWN" | jq -r '.[] | "| \(.agent) | \(.calls) | \(.input_chars) | \(.output_chars) |"' >> "$SUMMARY_FILE"

DECISIONS_DIR="$CLAUDE_PROJECT_DIR/.claude/state/decisions"
if [ -d "$DECISIONS_DIR" ]; then
    DECISION_FILES=$(find "$DECISIONS_DIR" -maxdepth 1 -name "*.md" 2>/dev/null)
    if [ -n "$DECISION_FILES" ]; then
        echo "" >> "$SUMMARY_FILE"
        echo "## Decisions This Session" >> "$SUMMARY_FILE"
        echo "" >> "$SUMMARY_FILE"
        for df in $DECISION_FILES; do
            DNAME=$(basename "$df" .md)
            echo "- $DNAME" >> "$SUMMARY_FILE"
        done
    fi
fi

exit 0
