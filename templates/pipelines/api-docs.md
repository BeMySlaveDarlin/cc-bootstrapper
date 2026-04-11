---
name: "api-docs"
description: "Генерация API-контрактов"
triggers: [документация, api docs, контракт]
modes: [sequential]
capture: none
user_prompts: true
error_routing:
  agent_error: stop
phases:
  - id: 1
    name: SCAN
    needs: []
    gate: silent
    agent: lead
  - id: 2
    name: GENERATE
    needs: [1]
    gate: silent
agents:
  "{lang}-developer":
    phases: [2]
    input: [endpoint list, source code]
    output: contracts/{module}.md
---
