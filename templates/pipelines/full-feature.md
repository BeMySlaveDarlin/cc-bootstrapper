---
name: "full-feature"
description: "Полный цикл фичи: код + API docs + QA docs"
triggers: [полный цикл, feature, от начала до конца, фулл]
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
  - id: 7
    name: API_DOCS
    needs: [6]
    condition: has_api_endpoints
    gate: silent
  - id: 8
    name: QA_DOCS
    needs: [7]
    condition: has_api_endpoints
    gate: silent
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
    phases: [4, 7]
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
  qa-engineer:
    phases: [8]
    condition: has_api_endpoints
    input: [contracts/{module}.md, source code]
    output: qa/{module}-checklist.md
---

### [team]

TeamCreate("full-feature-{slug}")

# Phase 1: ANALYSIS
Agent(name="analyst", team_name=T)
  → SendMessage(to=lead): done + spec path
Gate: review
Cleanup: shutdown analyst

# Phase 2: ARCHITECTURE
Agent(name="{lang}-architect", team_name=T)
  → SendMessage(to=lead): done + plan path
Gate: review
Cleanup: shutdown {lang}-architect

# Phase 3: STORAGE (если has_db)
# (если has_db)
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
Cleanup: shutdown {lang}-test-developer, {lang}-reviewer

# Phase 7: API_DOCS (если has_api_endpoints, reuse {lang}-developer)
# {lang}-developer stays from Phase 4 (не shutdown в Phase 6 cleanup)
# Lead направляет developer на Phase 7:
  Lead → SendMessage(to={lang}-developer): "Phase 7: API_DOCS. Сгенерируй контракты."
  {lang}-developer → SendMessage(to=lead): done + contracts path
Gate: silent

# Phase 8: QA_DOCS (если has_api_endpoints)
# Lead спавнит qa-engineer после Phase 7 gate:
Agent(name="qa-engineer", team_name=T)
  → SendMessage(to=lead): done + checklist path
Gate: silent
Cleanup: shutdown all → TeamDelete
