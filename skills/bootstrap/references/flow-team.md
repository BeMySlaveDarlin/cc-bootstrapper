# Bootstrap — Team Flow

## Defaults

| Параметр | Значение |
|----------|----------|
| Agent mode | `auto` |
| Agent model | `sonnet` (генерация: `opus`) |
| References dir | `${CLAUDE_SKILL_DIR}/references/` |
| Templates | `${CLAUDE_PLUGIN_ROOT}/templates/` |
| Plugin root | `${CLAUDE_PLUGIN_ROOT}` |
| Cache | `.claude/.cache/` |
| State | `.claude/.cache/state.json` |

## Interaction pattern

Team-агенты не вызывают AskUserQuestion. Когда нужен ввод пользователя:

1. Агент записывает данные в `.claude/.cache/{step}-interaction.json`
2. Агент: `SendMessage(to="team-lead", summary="interaction required", message="interaction_required: .claude/.cache/{step}-interaction.json")`
3. Lead читает файл, вызывает AskUserQuestion
4. Lead: `SendMessage(to="{agent}", summary="user response", message="user_response: {ответ}")`

## Subagent prompt template

```
Прочитай {reference_path} и выполни.
Templates: ${CLAUDE_PLUGIN_ROOT}/templates/.
Plugin root: ${CLAUDE_PLUGIN_ROOT}.
TEAM MODE: не вызывай AskUserQuestion. Для ввода пользователя — запиши в .claude/.cache/{step}-interaction.json и SendMessage(to="team-lead", summary="interaction required", message="interaction_required: .claude/.cache/{step}-interaction.json").
По завершении: SendMessage(to="team-lead", summary="{step} done", message="done").
```

## Error protocol

| Событие | Действие |
|---------|----------|
| Agent error | Lead: AskUserQuestion → Повторить / Пропустить / Остановить |
| TeamCreate fail | Fallback: прочитай flow-sequential.md и выполни |
| Agent spawn fail mid-flow | Завершить фазу через Agent tool (sequential). Оставшиеся фазы — sequential |

## Shutdown

SendMessage(to="{agent}", message={"type": "shutdown_request"}) для каждого агента поимённо. После всех → TeamDelete.

---

## Resume Detection

Проверь `.claude/.cache/state.json`:

| Состояние | Действие |
|-----------|----------|
| Файл существует, валидный JSON | AskUserQuestion: "Найден незавершённый bootstrap. Продолжить / Заново / Отмена" |
| → Продолжить | Прочитай state.json → первый pending шаг → начни с него |
| → Заново | Удали `.claude/.cache/` → Phase A |
| → Отмена | Стоп |
| Файл существует, невалидный JSON | Удали `.claude/.cache/` → Phase A (corrupted state) |
| Файл не существует | Phase A |

---

## Phases

### Phase A — Init

```
TeamCreate(team_name="bootstrap")

Agent(name="initializer", team_name="bootstrap", model="sonnet", mode="auto",
  prompt="... step-init.md ...")
```

| Ожидание | Gate |
|----------|------|
| initializer → SendMessage(to="team-lead", summary="init done", message="done") | `.claude/.cache/state.json` существует |

После gate — shutdown initializer.

Прочитай `.claude/.cache/state.json` → `state.mode`:

| Mode | Действие |
|------|----------|
| empty | TeamDelete → Стоп |
| fresh | Phase B → C → D → E |
| resume | Phase B → первый pending → ... → E |
| patch | Phase D-patch → E |
| upgrade | Phase D-upgrade |

---

### Phase B — Configure (sequential, lead координирует)

Интерактивные шаги — lead задаёт вопросы. Agent tool (не team agents).

| Step | Owner | Reference |
|------|-------|-----------|
| Configure (3A) | subagent (Agent tool) | step-3-configure.md |
| Configure (3B) | lead asks via AskUserQuestion | — |
| Configure (3C) | subagent (Agent tool) | step-3-apply.md |
| Settings | subagent (Agent tool) | step-4-settings.md |
| Plugins (5A) | subagent (Agent tool) | step-5-plugins.md |
| Plugins (5B) | lead asks via AskUserQuestion | — |
| Plugins (5C) | subagent (Agent tool) | step-5-apply.md |

Settings и Plugins — только при `mode == "fresh"`. При upgrade — пропустить.

---

### Phase C — Preview (sequential)

| Step | Owner | Reference |
|------|-------|-----------|
| Preview | subagent (Agent tool) | step-6-preview.md |

| Результат | Действие |
|-----------|----------|
| done | Phase D |
| pause | TeamDelete → Стоп |
| change | Вернуться к Phase B |

---

### Phase D — Generate (team, параллельно)

Перед спавном — создать директории (lead, Bash):
```bash
mkdir -p .claude/{agents,skills,pipelines,scripts/hooks,memory/{decisions/archive,sessions},output/{contracts,qa,plans,reviews,state},input/{tasks,plans},database}
```

#### D1: analysis_depth != "light"

```
Agent(name="deep-analyzer", team_name="bootstrap", model="opus", mode="auto",
  prompt="... step-7-analyze.md ...")

Agent(name="infra-gen", team_name="bootstrap", model="sonnet", mode="auto",
  prompt="... step-8-infra.md ... Стартуй сразу, не жди deep-analyzer.")

# Для КАЖДОГО lang из state.config.langs:
Agent(name="lang-gen-{lang}", team_name="bootstrap", model="opus", mode="auto",
  prompt="... step-8-lang.md для {lang} ... Жди сообщение от deep-analyzer (done + файлы в .claude/.cache/deep/). По завершении: SendMessage(to='team-lead', summary='lang-gen done', message='done').")

# common-gen стартует ПОСЛЕ всех lang-gen (ждёт per-lang фрагменты code-style/testing)
# Lead ждёт done от всех lang-gen, затем спавнит common-gen:
Agent(name="common-gen", team_name="bootstrap", model="sonnet", mode="auto",
  prompt="... step-8-common.md ... Per-lang фрагменты готовы в .claude/.cache/skills/.")
```

Flow:
```
deep-analyzer ──→ SendMessage(to="lang-gen-php"): done
                → SendMessage(to="lang-gen-typescript"): done
                → SendMessage(to="team-lead"): done
infra-gen ─────→ SendMessage(to="team-lead"): done
lang-gen-{lang} → SendMessage(to="team-lead"): done

lead ждёт done от ВСЕХ lang-gen + infra-gen, затем спавнит:
common-gen ────→ SendMessage(to="team-lead"): done
```

deep-analyzer шлёт каждому lang-gen поимённо (не wildcard).
common-gen стартует только после всех lang-gen — ему нужны per-lang фрагменты из .claude/.cache/skills/.

#### D2: analysis_depth == "light"

Без deep-analyzer. lang-gen стартуют сразу. infra-gen стартует сразу. common-gen — после всех lang-gen.

#### Gate

Lead ждёт done от ВСЕХ агентов. Shutdown всех после gate.

Partial failure: прочитать gen-report-8-*.json → если есть failed → AskUserQuestion.

---

### Phase D-patch

| Step | Owner | Reference |
|------|-------|-----------|
| Patch | subagent (Agent tool) | step-patch.md |

После patch → Phase E.

---

### Phase D-upgrade

```
Agent(name="upgrader", team_name="bootstrap", model="opus", mode="auto",
  prompt="... step-upgrade.md U.0-U.3 ... Known templates: ${CLAUDE_PLUGIN_ROOT}/known-templates.json.")
```

Upgrader → SendMessage(to="team-lead"): interaction_required (U.2 — выбор файлов).
Lead обрабатывает interaction, отвечает upgrader-у.
Upgrader → SendMessage(to="team-lead"): done.

Shutdown upgrader. Затем:
- Phase B (Configure only, без Settings/Plugins)
- Phase C (Preview)
- Phase D (Generate)

После генерации:
```
Agent(name="restorer", team_name="bootstrap", model="opus", mode="auto",
  prompt="... step-upgrade.md U.5-U.6 ...")
```

Restorer → SendMessage(to="team-lead"): done. Shutdown → Phase E.

---

### Phase E — Finalize

```
Agent(name="finalizer", team_name="bootstrap", model="opus", mode="auto",
  prompt="... step-finalize.md ...")
```

Finalizer → SendMessage(to="team-lead"): done.

Shutdown finalizer → TeamDelete.
