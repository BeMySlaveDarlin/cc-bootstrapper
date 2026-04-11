---
name: "brainstorm"
description: "Мозговой штурм: анализ идеи с нескольких ракурсов"
triggers: [обсудим, идея, brainstorm, брейншторм, побрейнштормим, как лучше, варианты, подход, продумать, предложи]
modes: [sequential, team]
capture: partial
user_prompts: true
phases:
  - id: 1
    name: FRAME
    needs: []
    gate: review
    artifact: plans/{task-slug}-frame.md
  - id: 2
    name: PERSPECTIVES
    needs: [1]
    gate: review
    artifact: plans/{task-slug}-options.md
  - id: 3
    name: DECISION
    needs: [2]
    gate: confirm
    agent: lead
agents:
  analyst:
    phases: [1, 2]
    input: [description, memory/facts.md, memory/decisions/]
    output: plans/{task-slug}-frame.md
  "{lang}-architect":
    phases: [2]
    after: [analyst, storage-architect, devops]
    input: [plans/{task-slug}-frame.md]
    output: plans/{task-slug}-options.md
    notify: lead
  storage-architect:
    phases: [2]
    condition: has_storage
    input: [plans/{task-slug}-frame.md]
    notify: "{lang}-architect"
  devops:
    phases: [2]
    condition: has_devops_agent
    input: [plans/{task-slug}-frame.md]
    notify: "{lang}-architect"
---

### [team]

TeamCreate("brainstorm-{slug}")

# Phase 1: FRAME
Agent(name="analyst", team_name=T)
  → SendMessage(to=lead): done + frame path
Gate: review
Cleanup: (analyst stays for Phase 2)

# Phase 2: PERSPECTIVES (parallel)
Agent(name="analyst", team_name=T)  # reuse from Phase 1
# (если .claude/agents/storage-architect.md существует И has_storage)
Agent(name="storage-architect", team_name=T)
# (если .claude/agents/devops.md существует)
Agent(name="devops", team_name=T)
Agent(name="{lang}-architect", team_name=T)
  # after chain: architect ждёт ТОЛЬКО спавненных агентов.
  # Если storage-architect/devops не спавнены (condition=false) — пропускаются в after list.
  analyst → SendMessage(to={lang}-architect): perspective
  storage-architect (если спавнен) → SendMessage(to={lang}-architect): perspective
  devops (если спавнен) → SendMessage(to={lang}-architect): perspective
  {lang}-architect: consolidate все полученные perspectives → SendMessage(to=lead): options path
Gate: review
Cleanup: shutdown all

# Phase 3: DECISION (lead inline)
# Lead консолидирует результаты, формирует финальное решение
Gate: confirm
Cleanup: TeamDelete
