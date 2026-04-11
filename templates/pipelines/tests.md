---
name: "tests"
description: "Написание тестов для существующего кода"
triggers: [тесты, покрытие, unit test, coverage, test]
modes: [sequential, team]
capture: partial
user_prompts: true
error_routing:
  test_fail: {max_retries: 2, action: stop}
  review_block: retry_current
phases:
  - id: 1
    name: ANALYZE
    needs: []
    gate: review
    artifact: plans/{task-slug}.md
  - id: 2
    name: GENERATE
    needs: [1]
    gate: silent
  - id: 3
    name: VERIFY
    needs: [2]
    gate: silent
  - id: 4
    name: REVIEW
    needs: [3]
    gate: confirm
    artifact: reviews/{task-slug}-tests.md
agents:
  analyst:
    phases: [1]
    input: [target files, memory/facts.md]
    output: plans/{task-slug}.md
  "{lang}-test-developer":
    phases: [2, 3]
    input: [plans/{task-slug}.md, skills/testing/SKILL.md]
    output: test files
    notify: "{lang}-reviewer"
  "{lang}-reviewer":
    phases: [4]
    after: "{lang}-test-developer"
    input: [git diff]
    output: reviews/{task-slug}-tests.md
    notify: lead
    on_block:
      target: "{lang}-test-developer"
      max_retries: 2
---

### [team]

TeamCreate("tests-{slug}")

# Phase 1: ANALYZE
Agent(name="analyst", team_name=T)
  → SendMessage(to="lead", summary="done", message="done")
Gate: review
Cleanup: shutdown analyst

# Phase 2-3: GENERATE + VERIFY (per-lang)
Agent(name="{lang}-test-developer", team_name=T)
Agent(name="{lang}-reviewer", team_name=T)
  {lang}-test-developer → SendMessage(to="{lang}-reviewer", summary="done", message="done")
  {lang}-reviewer: BLOCK → SendMessage(to="{lang}-test-developer", summary="fix", message="fix")
                   PASS → SendMessage(to="lead", summary="verdict", message="verdict")
Gate: confirm
Cleanup: shutdown all → TeamDelete
