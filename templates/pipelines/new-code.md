---
name: "new-code"
description: "Полный цикл создания нового кода"
triggers: [новый, добавь, создай, фича, модуль, эндпоинт]
modes: [sequential, team]
capture: full
user_prompts: true
error_routing:
  test_fail: {max_retries: 2, action: stop}
  review_block: retry_current
phases:
  - id: 1
    name: ANALYSIS
    needs: []
    gate: review
    artifact: plans/{task-slug}-spec.md
  - id: 2
    name: ARCHITECTURE
    needs: [1]
    gate: review
    artifact: plans/{task-slug}.md
  - id: 3
    name: STORAGE
    needs: [2]
    condition: has_db
    gate: silent
  - id: 4
    name: CODE
    needs: [2]
    gate: silent
  - id: 5
    name: TESTS
    needs: [4]
    gate: silent
  - id: 6
    name: REVIEW
    needs: [5]
    gate: confirm
    artifact: reviews/{task-slug}-{lang}.md
agents:
  analyst:
    phases: [1]
    input: [description, memory/facts.md, memory/decisions/, database/schema.sql]
    output: plans/{task-slug}-spec.md
  "{lang}-architect":
    phases: [2]
    input: [plans/{task-slug}-spec.md, skills/architecture/SKILL.md]
    output: plans/{task-slug}.md
  storage-architect:
    phases: [3]
    condition: has_db
    input: [plans/{task-slug}.md, skills/storage/SKILL.md, database/schema.sql]
    output: migrations
  "{lang}-developer":
    phases: [4]
    input: [plans/{task-slug}.md, skills/code-style/SKILL.md]
    output: plans/{task-slug}-impl-{lang}.md
    notify: "{lang}-test-developer"
  "{lang}-test-developer":
    phases: [5]
    after: "{lang}-developer"
    input: [plans/{task-slug}-impl-{lang}.md, skills/testing/SKILL.md]
    output: plans/{task-slug}-tests-{lang}.md
    notify: "{lang}-reviewer"
  "{lang}-reviewer":
    phases: [6]
    after: "{lang}-test-developer"
    input: [git diff, skills/code-style/SKILL.md]
    output: reviews/{task-slug}-{lang}.md
    notify: lead
    on_block:
      target: "{lang}-developer"
      max_retries: 2
---

### [team]

TeamCreate("new-code-{slug}")

# Phase 1: ANALYSIS
Agent(name="analyst", team_name=T)
  → SendMessage(to=lead): done + path to spec
Gate: review
Cleanup: shutdown analyst

# Phase 2: ARCHITECTURE
Agent(name="{lang}-architect", team_name=T)
  → SendMessage(to=lead): done + path to plan
Gate: review
Cleanup: shutdown {lang}-architect

# Phase 3: STORAGE (если has_db)
# (если .claude/agents/storage-architect.md существует И has_db)
Agent(name="storage-architect", team_name=T)
  → SendMessage(to=lead): done
Gate: silent
Cleanup: shutdown storage-architect

# Phase 4-6: CODE → TESTS → REVIEW (per-lang)
Agent(name="{lang}-developer", team_name=T)
Agent(name="{lang}-test-developer", team_name=T)
Agent(name="{lang}-reviewer", team_name=T)
  {lang}-developer → SendMessage(to={lang}-test-developer): done + impl path
  {lang}-test-developer → SendMessage(to={lang}-reviewer): done + tests path
  {lang}-reviewer: BLOCK → SendMessage(to={lang}-developer): fix + comments
                   PASS → SendMessage(to=lead): verdict + review path
Gate: confirm
Cleanup: shutdown all → TeamDelete
