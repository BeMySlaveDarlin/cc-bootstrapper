---
name: "fix-code"
description: "Диагностика и исправление бага"
triggers: [баг, ошибка, fix, не работает, сломалось, regression]
modes: [sequential, team]
capture: partial
user_prompts: true
error_routing:
  test_fail: {max_retries: 2, action: stop}
  review_block: retry_current
phases:
  - id: 1
    name: DIAGNOSIS
    needs: []
    gate: review
    artifact: plans/{task-slug}.md
  - id: 2
    name: FIX
    needs: [1]
    gate: silent
  - id: 3
    name: TESTS
    needs: [2]
    gate: silent
  - id: 4
    name: REVIEW
    needs: [3]
    gate: confirm
    artifact: reviews/{task-slug}-{lang}.md
agents:
  analyst:
    phases: [1]
    input: [description, memory/facts.md, memory/issues.md]
    output: plans/{task-slug}.md
  "{lang}-developer":
    phases: [2]
    input: [plans/{task-slug}.md]
    output: fixed files
    notify: "{lang}-test-developer"
  "{lang}-test-developer":
    phases: [3]
    after: "{lang}-developer"
    input: [fixed files, bug description]
    output: regression test
    notify: "{lang}-reviewer"
  "{lang}-reviewer":
    phases: [4]
    after: "{lang}-test-developer"
    input: [git diff]
    output: reviews/{task-slug}-{lang}.md
    notify: lead
    on_block:
      target: "{lang}-developer"
      max_retries: 2
---

### [team]

TeamCreate("fix-code-{slug}")

# Phase 1: DIAGNOSIS
Agent(name="analyst", team_name=T)
  → SendMessage(to=lead): done + diagnosis path
Gate: review
Cleanup: shutdown analyst

# Phase 2-4: FIX → TESTS → REVIEW (per-lang)
Agent(name="{lang}-developer", team_name=T)
Agent(name="{lang}-test-developer", team_name=T)
Agent(name="{lang}-reviewer", team_name=T)
  {lang}-developer → SendMessage(to={lang}-test-developer): done
  {lang}-test-developer → SendMessage(to={lang}-reviewer): done
  {lang}-reviewer: BLOCK → SendMessage(to={lang}-developer): fix + comments
                   PASS → SendMessage(to=lead): verdict
Gate: confirm
Cleanup: shutdown all → TeamDelete
