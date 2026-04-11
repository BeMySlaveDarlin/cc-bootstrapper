---
name: "qa-docs"
description: "QA-чеклисты и Postman-коллекции"
triggers: [чеклист, QA, postman]
modes: [sequential]
capture: none
user_prompts: true
error_routing:
  agent_error: stop
phases:
  - id: 1
    name: INPUT
    needs: []
    gate: silent
    agent: lead
  - id: 2
    name: CHECKLIST
    needs: [1]
    gate: silent
  - id: 3
    name: AUTOMATION
    needs: [2]
    gate: silent
agents:
  qa-engineer:
    phases: [2, 3]
    input: [contracts/{module}.md, source code]
    output: qa/{module}-checklist.md
---
