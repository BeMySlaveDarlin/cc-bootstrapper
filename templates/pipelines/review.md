---
name: "review"
description: "Ревью существующего кода"
triggers: [ревью, проверь, review, посмотри код]
modes: [sequential]
capture: review
user_prompts: true
error_routing:
  agent_error: stop
phases:
  - id: 1
    name: REVIEW
    needs: []
    gate: silent
  - id: 2
    name: REPORT
    needs: [1]
    gate: confirm
    artifact: reviews/{task-slug}-report.md
    agent: lead
agents:
  "{lang}-reviewer":
    phases: [1]
    input: [diff/files, skills/code-style/SKILL.md]
    output: reviews/{task-slug}-{lang}.md
---
