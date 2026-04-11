---
name: "github"
description: "Операции с GitHub через gh CLI"
triggers: [github, PR, pull request, issue, "issue #"]
modes: [sequential]
capture: none
user_prompts: false
error_routing:
  agent_error: stop
  timeout: stop
phases:
  - id: 1
    name: ANALYZE
    needs: []
    agent: lead
    gate: silent
    artifact: plans/github-op.md
  - id: 2
    name: EXECUTE
    needs: [1]
    gate: silent
    artifact: output/github-result.md
  - id: 3
    name: VERIFY
    needs: [2]
    agent: lead
    gate: silent
    condition: is_critical_op
  - id: 4
    name: REPORT
    needs: [2]
    agent: lead
    gate: silent
agents:
  devops:
    phases: [2]
    input: [plans/github-op.md, skills/github/SKILL.md]
    output: output/github-result.md
    on_block: {action: stop, message: "GitHub CLI error"}
---

# Pipeline: GitHub

## Phase 1: ANALYZE (lead inline)
1. Определи тип операции из запроса
2. Собери параметры (owner, repo, PR/issue number, branch, etc.)
3. Запиши план в `plans/github-op.md`

## Phase 2: EXECUTE

Task(.claude/agents/devops.md, subagent_type: "general-purpose"):
  Вход: параметры операции + `.claude/skills/github/SKILL.md`
  Выход: результат gh CLI вызова
  Ограничение: read-only (кроме create PR/issue)
  Верни: summary (операция, статус, URL)

## Phase 3: VERIFY (условная — только для критичных операций)
condition: is_critical_op (merge PR, close issue, create release)
- Повторно проверь статус объекта через `gh`

## Phase 4: REPORT (lead inline)
- Summary с URL
- Обнови memory если релевантно
