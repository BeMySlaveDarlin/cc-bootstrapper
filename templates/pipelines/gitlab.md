---
name: "gitlab"
description: "Операции с GitLab через MCP"
triggers: [gitlab, MR, merge request, issue, "задача #"]
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
    artifact: plans/gitlab-op.md
  - id: 2
    name: EXECUTE
    needs: [1]
    gate: silent
    artifact: output/gitlab-result.md
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
    input: [plans/gitlab-op.md, skills/gitlab/SKILL.md]
    output: output/gitlab-result.md
    on_block: {action: stop, message: "GitLab MCP error"}
---

# Pipeline: GitLab

## Phase 1: ANALYZE (lead inline)
1. Определи тип операции из запроса
2. Собери параметры (projectId, IID, branch, etc.)
3. Запиши план в `plans/gitlab-op.md`

## Phase 2: EXECUTE

Task(.claude/agents/devops.md, subagent_type: "general-purpose"):
  Вход: параметры операции + `.claude/skills/gitlab/SKILL.md`
  Выход: результат MCP-вызова
  Ограничение: read-only
  Верни: summary (операция, статус, URL)

## Phase 3: VERIFY (условная — только для критичных операций)
condition: is_critical_op (merge MR, delete issue, create release)
- Повторно запроси объект для подтверждения статуса

## Phase 4: REPORT (lead inline)
- Summary с URL
- Обнови memory если релевантно
