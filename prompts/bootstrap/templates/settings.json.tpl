{
  "permissions": {
    "allow": [
      "Read(**)",
      "Write(**)",
      "WebSearch",
      "WebFetch",
      "Bash({CONTAINER_CMD}:*)",
      "Bash(make:*)",
      "Bash(git log:*)",
      "Bash(git show:*)",
      "Bash(git diff:*)",
      "Bash(git status:*)",
      "Bash(git rev-parse:*)",
      "Bash(git branch:*)",
      "Bash(curl:*)"
    ]
  },
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Task",
        "hooks": [
          {
            "type": "command",
            "command": "bash $CLAUDE_PROJECT_DIR/.claude/scripts/hooks/track-agent.sh"
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash $CLAUDE_PROJECT_DIR/.claude/scripts/hooks/maintain-memory.sh"
          }
        ]
      }
    ]
  }
}
