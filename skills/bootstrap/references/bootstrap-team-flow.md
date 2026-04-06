# Bootstrap — Team Flow

> Альтернативный режим запуска через Agent Teams. Активируется выбором "Team" при старте.
> Требует `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`.

## Общие правила

> Проверка доступности Agent Teams уже выполнена оркестратором (SKILL.md). Сюда попадаем только если TeamCreate доступен.

- Все субагенты запускаются с mode: "auto"
- File-based coordination: агенты общаются через файлы в `.bootstrap-cache/`
- При ошибке team spawn → fallback на sequential для оставшихся шагов

### Интерактивность в team mode

**КРИТИЧЕСКИ ВАЖНО:** Team-агенты НЕ вызывают AskUserQuestion. Их output не виден пользователю — только lead видит контекст диалога.

Паттерн для интерактивных шагов:
1. Агент собирает данные / формирует вопрос / считает diff
2. Агент записывает результат в файл `.bootstrap-cache/{step}-interaction.json`
3. Агент отправляет `SendMessage(to=lead): interaction_required + путь к файлу`
4. **Lead** читает файл, показывает пользователю, вызывает AskUserQuestion
5. **Lead** отправляет ответ агенту через `SendMessage(to=agent): user_response + ответ`
6. Агент продолжает работу с ответом

Формат `.bootstrap-cache/{step}-interaction.json`:
```json
{
  "type": "ask_user",
  "question": "Как применить изменения?",
  "header": "Settings diff",
  "context": "... diff или описание ...",
  "options": [
    {"label": "Принять все", "description": "..."},
    {"label": "Пропустить", "description": "..."}
  ]
}
```

---

## Phase A — Сканирование

```python
TeamCreate(team_name="bootstrap-scan")

Agent(name="scanner", team_name="bootstrap-scan", model="sonnet", prompt="""
Прочитай файл ${CLAUDE_SKILL_DIR}/references/step-1-scan.md и выполни ВСЕ инструкции.
Шаблоны: ${CLAUDE_SKILL_DIR}/../../templates/.
TEAM MODE: НЕ вызывай AskUserQuestion. Если нужен ввод — SendMessage(to=lead): interaction_required + данные.
По завершении: SendMessage(to="detector"): done + путь к state.json.
""")

Agent(name="detector", team_name="bootstrap-scan", model="sonnet", prompt="""
Жди сообщение от scanner (done + state.json готов).
Прочитай файл ${CLAUDE_SKILL_DIR}/references/step-2-detect.md и выполни ВСЕ инструкции.
TEAM MODE: НЕ вызывай AskUserQuestion. Если нужен ввод — SendMessage(to=lead): interaction_required + данные.
По завершении: SendMessage(to=lead): done.
""")
```

### Flow
```
scanner → detector → lead
```

**Gate:** lead получил done от detector, `.bootstrap-cache/state.json` содержит `steps.2.status == "completed"`.

```python
TeamDelete(team_name="bootstrap-scan")
```

→ `[Phase A] Сканирование ✓`

**Проверка empty mode:** Прочитай `.bootstrap-cache/state.json` → `state.mode`. Если `"empty"` → вывести `[BOOTSTRAP] Проект пустой. Заполни .claude/input/plans/project-spec.md и запусти повторно.` → **ОСТАНОВИСЬ.**

---

## Phase B — Настройка (interactive)

Фазы 3A → 3B → 3C — последовательно, оркестратор задаёт вопросы (3B, 5B). Идентично основному flow.

**После 3C — steps 4 и 5 sequential (оба зависят от ToolSearch/AskUserQuestion):**

Step 4 — Settings:

Agent tool (mode: "auto"):
  prompt: "Прочитай файл ${CLAUDE_SKILL_DIR}/references/step-4-settings.md и выполни ВСЕ инструкции. ПЕРЕД началом работы загрузи AskUserQuestion: ToolSearch(query: 'select:AskUserQuestion', max_results: 1). По завершении верни done или error."

→ `[4/10] Settings.json ✓`

Step 5A — Plugin scan (нужен ToolSearch для проверки рантайма):

Agent tool (mode: "auto"):
  prompt: "Прочитай файл ${CLAUDE_SKILL_DIR}/references/step-5-plugins.md и выполни ВСЕ инструкции. По завершении верни JSON-блок с результатами сканирования + done."

→ `[5/10] Плагины — сканирование ✓`

Далее оркестратор:
- **Фаза 5B** — задаёт вопросы пользователю (из результата 5A)
- **Фаза 5C** — Agent tool: step-5-apply.md

→ `[Phase B] Настройка ✓`

---

## Phase C — Превью (без team)

Agent tool (mode: "auto"):
  prompt: step-6-preview.md

**PAUSE POINT:**
AskUserQuestion:
  question: "Генерация запланирована. Продолжить?"
  header: "Preview"
  options:
    - {label: "Генерировать", description: "Запустить генерацию"}
    - {label: "Пауза", description: "Продолжить позже через /bootstrap"}
    - {label: "Изменить", description: "Вернуться к настройкам"}

→ `[Phase C] Превью ✓`

---

## Phase D — Генерация

Прочитай `.bootstrap-cache/state.json` → `config.langs`, `config.analysis_depth`.

### Вариант D1: analysis_depth != "light" (deep analysis + generation)

```python
TeamCreate(team_name="bootstrap-gen")

Agent(name="deep-analyzer", team_name="bootstrap-gen", model="opus", prompt="""
Прочитай файл ${CLAUDE_SKILL_DIR}/references/step-7-analyze.md и выполни ВСЕ инструкции.
Результаты записывай в .bootstrap-cache/deep/.
По завершении: SendMessage(to="lang-gen-*"): broadcast done + список файлов в deep/.
Если нет агентов lang-gen-* (light mode) — SendMessage(to=lead): done.
""")

Agent(name="common-gen", team_name="bootstrap-gen", model="sonnet", prompt="""
НЕ ЖДАЯ deep-analyzer — стартуй сразу.
Прочитай файл ${CLAUDE_SKILL_DIR}/references/step-8-common.md и выполни ВСЕ инструкции.
Шаблоны: ${CLAUDE_SKILL_DIR}/../../templates/.
TEAM MODE: НЕ вызывай AskUserQuestion. Если нужен ввод — SendMessage(to=lead): interaction_required + данные.
По завершении: SendMessage(to=lead): done + путь к gen-report-8-common.json.
""")

Agent(name="infra-gen", team_name="bootstrap-gen", model="sonnet", prompt="""
НЕ ЖДАЯ deep-analyzer — стартуй сразу.
Прочитай файл ${CLAUDE_SKILL_DIR}/references/step-8-infra.md и выполни ВСЕ инструкции.
Шаблоны: ${CLAUDE_SKILL_DIR}/../../templates/.
TEAM MODE: НЕ вызывай AskUserQuestion. Если нужен ввод — SendMessage(to=lead): interaction_required + данные.
По завершении: SendMessage(to=lead): done + путь к gen-report-8-infra.json.
""")

# Для КАЖДОГО {lang} из config.langs — отдельный агент:
Agent(name="lang-gen-{lang}", team_name="bootstrap-gen", model="opus", prompt="""
Жди сообщение от deep-analyzer (done + файлы в deep/).
Прочитай файл ${CLAUDE_SKILL_DIR}/references/step-8-lang.md и выполни ВСЕ инструкции для языка {lang}.
Шаблоны: ${CLAUDE_SKILL_DIR}/../../templates/.
TEAM MODE: НЕ вызывай AskUserQuestion. Если нужен ввод — SendMessage(to=lead): interaction_required + данные.
По завершении: SendMessage(to=lead): done + путь к gen-report-8-{lang}.json.
""")
```

### Вариант D2: analysis_depth == "light" (только generation)

```python
TeamCreate(team_name="bootstrap-gen")

Agent(name="common-gen", team_name="bootstrap-gen", model="sonnet", prompt="""
Прочитай файл ${CLAUDE_SKILL_DIR}/references/step-8-common.md и выполни ВСЕ инструкции.
Шаблоны: ${CLAUDE_SKILL_DIR}/../../templates/.
TEAM MODE: НЕ вызывай AskUserQuestion. Если нужен ввод — SendMessage(to=lead): interaction_required + данные.
По завершении: SendMessage(to=lead): done.
""")

Agent(name="infra-gen", team_name="bootstrap-gen", model="sonnet", prompt="""
Прочитай файл ${CLAUDE_SKILL_DIR}/references/step-8-infra.md и выполни ВСЕ инструкции.
Шаблоны: ${CLAUDE_SKILL_DIR}/../../templates/.
TEAM MODE: НЕ вызывай AskUserQuestion. Если нужен ввод — SendMessage(to=lead): interaction_required + данные.
По завершении: SendMessage(to=lead): done.
""")

# Для КАЖДОГО {lang} из config.langs — отдельный агент:
Agent(name="lang-gen-{lang}", team_name="bootstrap-gen", model="opus", prompt="""
Стартуй сразу (deep analysis пропущен).
Прочитай файл ${CLAUDE_SKILL_DIR}/references/step-8-lang.md и выполни ВСЕ инструкции для языка {lang}.
Шаблоны: ${CLAUDE_SKILL_DIR}/../../templates/.
TEAM MODE: НЕ вызывай AskUserQuestion. Если нужен ввод — SendMessage(to=lead): interaction_required + данные.
По завершении: SendMessage(to=lead): done + путь к gen-report-8-{lang}.json.
""")
```

### Flow (оба варианта)
```
D1: deep-analyzer ──→ lang-gen-php (∥) lang-gen-ts (∥) ... → lead
    common-gen (∥) ──────────────────────────────────────→ lead
    infra-gen  (∥) ──────────────────────────────────────→ lead

D2: common-gen (∥) lang-gen-php (∥) lang-gen-ts (∥) infra-gen → lead
```

**Gate:** lead получил done от всех агентов, все `gen-report-8-*.json` записаны.

```python
TeamDelete(team_name="bootstrap-gen")
```

→ `[Phase D] Генерация ✓`

---

## Phase E — Финализация

```python
TeamCreate(team_name="bootstrap-final")

Agent(name="claude-md-gen", team_name="bootstrap-final", model="opus", prompt="""
Прочитай файл ${CLAUDE_SKILL_DIR}/references/step-9-claude-md.md и выполни ВСЕ инструкции.
TEAM MODE: НЕ вызывай AskUserQuestion. Если нужен ввод — SendMessage(to=lead): interaction_required + данные.
По завершении: SendMessage(to="finalizer"): done + CLAUDE.md записан.
""")

Agent(name="finalizer", team_name="bootstrap-final", model="sonnet", prompt="""
Жди сообщение от claude-md-gen (done).
Прочитай файл ${CLAUDE_SKILL_DIR}/references/step-10-finalize.md и выполни ВСЕ инструкции.
TEAM MODE: НЕ вызывай AskUserQuestion. Если нужен ввод — SendMessage(to=lead): interaction_required + данные.
По завершении: SendMessage(to=lead): done + .bootstrap-version записан.
""")
```

### Flow
```
claude-md-gen → finalizer → lead
```

**Gate:** lead получил done от finalizer, `.bootstrap-version` записан.

```python
TeamDelete(team_name="bootstrap-final")
```

→ `[Phase E] Финализация ✓`

---

## Итог

```
[BOOTSTRAP COMPLETE — TEAM MODE]
Фаз: 5 (A scan, B config, C preview, D gen, E finalize)
Teams создано: 4 (bootstrap-scan, bootstrap-config, bootstrap-gen, bootstrap-final)
```

## Fallback

Если на любой фазе TeamCreate или Agent spawn упал:
1. Сообщи: `[TEAM FALLBACK] Phase {X} — spawn fail, переключаюсь на sequential`
2. Выполни оставшиеся шаги последовательно (основной flow из SKILL.md)
3. НЕ перезапускай уже выполненные шаги — resume по state.json

### Granular fallback для фазы D (генерация)

Если на фазе D (генерация) team agent упал:
1. Прочитай `gen-report-8-*.json` для определения УЖЕ записанных файлов
2. Sequential fallback ТОЛЬКО для языков/файлов без successful gen-report или с непустым `failed[]`
3. НЕ переделывай файлы из `written[]` — они уже на диске
4. В prompt sequential-агента передай список конкретных файлов для генерации, а не весь шаг целиком
