{
  "permissions": {
    "allow": [
      "Bash({CONTAINER_CMD}:*)",
      "Bash(make:*)",
      "Bash({SYNTAX_CHECK_BINARY}:*)",
      "Bash({TEST_BINARY}:*)",
      "Bash(git log:*)",
      "Bash(git show:*)",
      "Bash(git add:*)",
      "Bash(git rev-parse:*)",
      "Bash(chmod:*)",
      "Bash(mkdir:*)",
      "Bash(touch:*)",
      "Bash(bash -n:*)",
      "Bash(bash .claude/scripts/hooks/*)",
      "Bash(bash .claude/scripts/verify-bootstrap.sh)",
      "Bash(curl:*)",
      "WebFetch(domain:www.anthropic.com)",
      "WebFetch(domain:claude.com)",
      "WebSearch"
    ],
    "deny": [],
    "ask": []
  },
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Task",
        "hooks": [
          {
            "type": "command",
            "command": "bash $CLAUDE_PROJECT_DIR/.claude/scripts/hooks/track-agent.sh"
          },
          {
            "type": "command",
            "command": "bash $CLAUDE_PROJECT_DIR/.claude/scripts/hooks/update-schema.sh"
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash $CLAUDE_PROJECT_DIR/.claude/scripts/hooks/update-schema.sh"
          },
          {
            "type": "command",
            "command": "bash $CLAUDE_PROJECT_DIR/.claude/scripts/hooks/maintain-memory.sh"
          },
          {
            "type": "command",
            "command": "bash $CLAUDE_PROJECT_DIR/.claude/scripts/hooks/git-context.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash $CLAUDE_PROJECT_DIR/.claude/scripts/hooks/session-summary.sh"
          }
        ]
      }
    ]
  }
}
