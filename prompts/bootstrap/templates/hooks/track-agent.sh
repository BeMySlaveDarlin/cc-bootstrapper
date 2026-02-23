#!/bin/bash
set -uo pipefail
ERR_LOG="${CLAUDE_PROJECT_DIR:-.}/.claude/memory/.hook-errors.log"
trap 'echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] ERROR in $(basename "$0"):$LINENO" >> "$ERR_LOG" 2>/dev/null; exit 0' ERR

LOG_DIR="$CLAUDE_PROJECT_DIR/.claude/memory"
LOG_FILE="$LOG_DIR/usage.jsonl"
mkdir -p "$LOG_DIR"

INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')

if [ "$TOOL_NAME" != "Task" ]; then
    exit 0
fi

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')

AGENT_NAME=$(echo "$INPUT" | jq -r '.tool_input.prompt // ""' | grep -oP '\.claude/agents/\K[^.]+' | head -1)
if [ -z "$AGENT_NAME" ]; then
    AGENT_NAME=$(echo "$INPUT" | jq -r '.tool_input.description // ""' | tr '[:upper:]' '[:lower:]')
fi
if [ -z "$AGENT_NAME" ]; then
    AGENT_NAME="unknown-agent"
fi

INPUT_CHARS=$(echo "$INPUT" | jq -r '.tool_input | tostring' | wc -c)
OUTPUT_CHARS=$(echo "$INPUT" | jq -r '.tool_response // "" | tostring' | wc -c)

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
BRANCH=$(cd "$CLAUDE_PROJECT_DIR" && git branch --show-current 2>/dev/null || echo "unknown")

jq -n \
    --arg ts "$TIMESTAMP" \
    --arg sid "$SESSION_ID" \
    --arg agent "$AGENT_NAME" \
    --arg branch "$BRANCH" \
    --argjson in_chars "$INPUT_CHARS" \
    --argjson out_chars "$OUTPUT_CHARS" \
    '{
        timestamp: $ts,
        session_id: $sid,
        agent: $agent,
        branch: $branch,
        input_chars: $in_chars,
        output_chars: $out_chars
    }' >> "$LOG_FILE"

exit 0
