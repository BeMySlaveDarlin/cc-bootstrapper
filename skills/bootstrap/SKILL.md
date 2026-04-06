---
name: bootstrap
description: Генерирует полную .claude/ структуру автоматизации для любого проекта — агенты, пайплайны, скиллы, memory, hooks, settings. Автоопределение режима fresh/validate/resume.
user-invocable: true
argument-hint: "[meta-prompt-file]"
---

# Bootstrap v8 — Оркестратор

**Все вопросы пользователю — ТОЛЬКО через AskUserQuestion.**

Ты — диспетчер. Твоя работа состоит РОВНО из трёх действий:
1. Вызвать Agent tool с указанным prompt
2. Дождаться результата
3. Вывести прогресс и перейти к следующему шагу

Если субагент вернул error — спроси пользователя через AskUserQuestion.
Если субагент вернул done — выведи прогресс и вызови следующий Agent tool.

## SendMessage — обязательный формат

Когда отправляешь сообщение субагенту через SendMessage, **ВСЕГДА** указывай `summary` (5-10 слов, превью для UI):

```
SendMessage:
  to: "{agent-name}"
  message: "текст сообщения"
  summary: "краткое описание сообщения"
```

Без `summary` вызов упадёт с ошибкой. Это касается любого SendMessage со строковым message.

Ты не принимаешь решений. Ты не читаешь файлы проекта. Ты не пишешь файлы.
Ты вызываешь Agent tool ровно так, как написано ниже, подставляя пути.

## Prompt и mode для субагентов

Все субагенты запускаются с mode: "auto".

## Deferred tools — инструкция для субагентов

AskUserQuestion и другие интерактивные tools — deferred. Субагенты не видят их по умолчанию.

**КАЖДЫЙ prompt субагента ДОЛЖЕН содержать эту преамбулу:**

```
ПЕРЕД началом работы загрузи необходимые tools:
- ToolSearch(query: "select:AskUserQuestion", max_results: 1)
Используй AskUserQuestion для всех вопросов пользователю. Без загрузки через ToolSearch он недоступен.

ФОРМАТ ВЫЗОВА AskUserQuestion — строго по схеме:
- Параметр questions (массив, 1-4 вопроса). Каждый элемент:
  - question (string, обязательный) — текст вопроса
  - header (string, обязательный) — короткий тег до 12 символов
  - options (массив 2-4 объектов, обязательный) — каждый: {label, description}
  - multiSelect (boolean, обязательный) — true для множественного выбора, false для одиночного
- НЕ передавай question/header/options на верхнем уровне — только внутри массива questions
- Пользователь всегда может выбрать "Other" (добавляется автоматически, НЕ включай в options)
```

## Выбор режима

Проверь доступность Agent Teams: `ToolSearch(query: "select:TeamCreate", max_results: 1)`.

Если TeamCreate найден (tool доступен):
  AskUserQuestion:
    question: "Agent Teams доступны. Какой режим?"
    header: "Mode"
    options:
      - {label: "Team", description: "Параллельные агенты, быстрее (~x2)"}
      - {label: "Sequential", description: "Последовательный, стабильнее"}

  → "Team": прочитай `${CLAUDE_SKILL_DIR}/references/bootstrap-team-flow.md` и выполни team flow. **ОСТАЛЬНАЯ ЧАСТЬ ЭТОГО ФАЙЛА НЕ ВЫПОЛНЯЕТСЯ.**
  → "Sequential": продолжай ниже.

Если TeamCreate НЕ найден → продолжай ниже (sequential).

## Resume Detection

Единственная логика оркестратора. Проверь файл `.bootstrap-cache/state.json`:

Файл существует → AskUserQuestion:
  question: "Найден незавершённый bootstrap. Что делать?"
  header: "Resume"
  options:
    - {label: "Продолжить", description: "Возобновить с последнего шага"}
    - {label: "Заново", description: "Удалить cache и начать с нуля"}
    - {label: "Отмена", description: "Ничего не делать"}

"Продолжить" → прочитай state.json → определи первый pending шаг → начни с него
"Заново" → удали .bootstrap-cache/ → начни с шага 1
"Отмена" → ОСТАНОВИСЬ

Файл не существует → начни с шага 1.

## При ошибке субагента

AskUserQuestion:
  question: "Ошибка на шаге N. Что делать?"
  header: "Error"
  options: ["Повторить", "Пропустить", "Остановить"]

## ПОРЯДОК ЗАПУСКА

### Шаг 1 — Сканирование проекта

Agent tool (mode: "auto"):
  prompt: "Прочитай файл ${CLAUDE_SKILL_DIR}/references/step-1-scan.md и выполни ВСЕ инструкции. Шаблоны: ${CLAUDE_SKILL_DIR}/../../templates/. ПЕРЕД началом работы загрузи AskUserQuestion: ToolSearch(query: 'select:AskUserQuestion', max_results: 1). Все вопросы пользователю — только через AskUserQuestion. По завершении верни done или error."

→ `[1/10] Сканирование проекта ✓`

### Шаг 2 — Определение режима

Agent tool (mode: "auto"):
  prompt: "Прочитай файл ${CLAUDE_SKILL_DIR}/references/step-2-detect.md и выполни ВСЕ инструкции. ПЕРЕД началом работы загрузи AskUserQuestion: ToolSearch(query: 'select:AskUserQuestion', max_results: 1). Все вопросы пользователю — только через AskUserQuestion. По завершении верни done или error."

→ `[2/10] Определение режима ✓`

**Проверка empty mode:** Прочитай `.bootstrap-cache/state.json` → `state.mode`. Если `"empty"` → вывести `[BOOTSTRAP] Проект пустой. Заполни .claude/input/plans/project-spec.md и запусти повторно.` → **ОСТАНОВИСЬ.**

### Шаг 3 — Настройка bootstrap (3 фазы, НЕ ПРОПУСКАЙ)

**ШАГ 3 СОСТОИТ ИЗ ТРЁХ ОБЯЗАТЕЛЬНЫХ ФАЗ. Переходить к шагу 4 ТОЛЬКО после выполнения ВСЕХ трёх.**

**Фаза 3A — Сбор:**

Agent tool (mode: "auto"):
  prompt: "Прочитай файл ${CLAUDE_SKILL_DIR}/references/step-3-configure.md и выполни ВСЕ инструкции. По завершении верни JSON-блок с вопросами и слово done, или skip если config уже заполнен."

→ `[3/10] Настройка — сбор ✓`

Если субагент вернул `skip` → перейди к шагу 4.

**Фаза 3B — СТОП. ТЫ (оркестратор) задаёшь вопросы пользователю:**

**ЭТО ТВОЯ РАБОТА, НЕ СУБАГЕНТА. НЕ ПРОПУСКАЙ. Без этой фазы config останется пустым и весь bootstrap сломается.**

1. Загрузи AskUserQuestion: ToolSearch(query: 'select:AskUserQuestion', max_results: 1)
2. Извлеки JSON-блок из результата 3A (между ```json и ```)
3. Подставь `estimates.standard` и `estimates.deep` в описания options вопроса "Анализ"
4. Возьми массив `questions_main.questions` из JSON и передай его в AskUserQuestion как параметр `questions`
5. Дождись ответов пользователя
6. Из ответов проверь: выбраны ли "Custom agents" / "Custom skills" / "Custom pipelines"
7. Если выбраны — собери follow-up вопросы из `questions_followup` (только для выбранных опций) и задай через AskUserQuestion (batch, до 3 вопросов)
8. Собери ВСЕ ответы в JSON:

   **Парсинг Other-ответа для analysis_depth:**
   Если ответ на вопрос "Анализ" не совпадает с preset labels ("light", "standard (рекомендуется)", "deep"):
   → Это Other-ввод. Парсинг:
   1. Извлечь режим — первое слово, fuzzy-match:
      - "standart", "стандарт", "стандартный", "средний" → "standard"
      - "глубокий", "полный", "full", "максимальный" → "deep"
      - "лёгкий", "легкий", "быстрый", "fast", "lite" → "light"
      - Не распознано → "standard" (default)
   2. Извлечь доп. инструкции — текст после первого разделителя (`+`, `,`, `:`, `;`):
      - Trim whitespace с обеих сторон
      - Если разделителя нет → `null`
   3. Подставить: `analysis_depth` = нормализованный режим, `custom_instructions` = доп. текст или `null`

   ```json
   {
     "features": [...],
     "analysis_depth": "standard",
     "custom_instructions": null,
     "permissions_level": "balanced",
     "git_permissions": ["Read", "Write"],
     "custom_agents": [{"name": "...", "role": "..."}],
     "custom_skills": [{"name": "...", "description": "..."}],
     "custom_pipelines": [{"name": "...", "trigger": "auto", "agents": "auto"}]
   }
   ```

**Фаза 3C — Применение:**

Agent tool (mode: "auto"):
  prompt: "Прочитай файл ${CLAUDE_SKILL_DIR}/references/step-3-apply.md и выполни ВСЕ инструкции. Вот ответы пользователя: {вставь собранный JSON из фазы 3B}. По завершении верни done или error."

→ `[3/10] Настройка bootstrap ✓`

**КОНТРОЛЬНАЯ ПРОВЕРКА:** После 3C прочитай `.bootstrap-cache/state.json` и убедись что `steps.3.status == "completed"` и `config` НЕ пустой. Если пустой — шаг 3 провален, повтори.

### Шаг 4 — Settings.json

Agent tool (mode: "auto"):
  prompt: "Прочитай файл ${CLAUDE_SKILL_DIR}/references/step-4-settings.md и выполни ВСЕ инструкции. ПЕРЕД началом работы загрузи AskUserQuestion: ToolSearch(query: 'select:AskUserQuestion', max_results: 1). Все вопросы пользователю — только через AskUserQuestion. По завершении верни done или error."

→ `[4/10] Settings.json ✓`

### Шаг 5 — Плагины и MCP (3 фазы, НЕ ПРОПУСКАЙ)

**ШАГ 5 СОСТОИТ ИЗ ТРЁХ ОБЯЗАТЕЛЬНЫХ ФАЗ. Переходить к шагу 6 ТОЛЬКО после выполнения ВСЕХ трёх.**

**Фаза 5A — Сканирование:**

Agent tool (mode: "auto"):
  prompt: "Прочитай файл ${CLAUDE_SKILL_DIR}/references/step-5-plugins.md и выполни ВСЕ инструкции. По завершении верни JSON-блок с результатами сканирования и слово done."

→ `[5/10] Плагины — сканирование ✓`

**Фаза 5B — СТОП. ТЫ (оркестратор) задаёшь вопросы пользователю:**

**ЭТО ТВОЯ РАБОТА, НЕ СУБАГЕНТА. НЕ ПРОПУСКАЙ. Без этой фазы плагины не будут настроены.**

1. Загрузи AskUserQuestion: ToolSearch(query: 'select:AskUserQuestion', max_results: 1)
2. Извлеки JSON-блок из результата 5A (между ```json и ```)
3. Запомни `auto` — эти плагины уже установлены, их permissions передашь в 5C
4. Если массив `questions` не пустой — задай пользователю пачками по 4 через AskUserQuestion
5. Дождись ответов пользователя
6. Для каждого ответа проверь: если это gate-вопрос (`_type: "mcp_gate"`) и ответ = condition из `questions_conditional` — добавь conditional вопросы в следующий batch
7. Задай conditional вопросы (если есть) через AskUserQuestion (batch, до 4)
8. Для "Из git config" (GitLab username) — выполни `git config user.name` и подставь результат
9. Собери ВСЕ ответы в JSON:
   ```json
   {
     "plugins_installed": ["playwright"],
     "plugins_skipped": ["typescript-lsp"],
     "mcp": {
       "gitlab": {
         "enabled": true,
         "api_url": "https://gitlab.com/api/v4",
         "username": "user",
         "token": "glpat-...",
         "features": {"pipeline": true, "milestone": true, "wiki": true}
       },
       "github": {"enabled": false},
       "docker": {"enabled": true}
     },
     "permissions": ["mcp__plugin_playwright_playwright__*", "mcp__gitlab__*", "mcp__docker__*"]
   }
   ```

Если массив `questions` пустой (всё уже установлено) — собери JSON только из `auto` данных и переходи к 5C.

**Фаза 5C — Применение:**

Agent tool (mode: "auto"):
  prompt: "Прочитай файл ${CLAUDE_SKILL_DIR}/references/step-5-apply.md и выполни ВСЕ инструкции. Вот данные: {вставь собранный JSON из фазы 5B}. По завершении верни done или error."

→ `[5/10] Плагины и MCP ✓`

**КОНТРОЛЬНАЯ ПРОВЕРКА:** После 5C прочитай `.bootstrap-cache/state.json` и убедись что `steps.5.status == "completed"`. Если нет — шаг 5 провален, повтори.

### Шаг 6 — План и превью

Agent tool (mode: "auto"):
  prompt: "Прочитай файл ${CLAUDE_SKILL_DIR}/references/step-6-preview.md и выполни ВСЕ инструкции. Шаблоны: ${CLAUDE_SKILL_DIR}/../../templates/. ПЕРЕД началом работы загрузи AskUserQuestion: ToolSearch(query: 'select:AskUserQuestion', max_results: 1). Все вопросы пользователю — только через AskUserQuestion. По завершении верни done или error."

**PAUSE POINT** (после субагента):
AskUserQuestion:
  question: "Генерация запланирована. Продолжить?"
  header: "Preview"
  options:
    - {label: "Генерировать", description: "Запустить генерацию"}
    - {label: "Пауза", description: "Продолжить позже через /bootstrap"}
    - {label: "Изменить", description: "Вернуться к настройкам"}

"Пауза" → ОСТАНОВИСЬ.
"Изменить" → запусти шаг 3 заново.
→ `[6/10] План и превью ✓`

### Шаг 7 — Глубокий анализ

Agent tool (mode: "auto"):
  prompt: "Прочитай файл ${CLAUDE_SKILL_DIR}/references/step-7-analyze.md и выполни ВСЕ инструкции. ПЕРЕД началом работы загрузи AskUserQuestion: ToolSearch(query: 'select:AskUserQuestion', max_results: 1). Все вопросы пользователю — только через AskUserQuestion. По завершении верни done или error."

→ `[7/10] Глубокий анализ ✓`

### Шаг 8 — Генерация (per-domain)

Прочитай `.bootstrap-cache/state.json` → `config.langs` для определения языков.

**Per-lang + Common + Infra — ПАРАЛЛЕЛЬНО:**

Для КАЖДОГО `{lang}` из `config.langs` — Agent tool (mode: "auto"):
  prompt: "Прочитай файл ${CLAUDE_SKILL_DIR}/references/step-8-lang.md и выполни ВСЕ инструкции для языка {lang}. Шаблоны: ${CLAUDE_SKILL_DIR}/../../templates/. ПЕРЕД началом работы загрузи AskUserQuestion: ToolSearch(query: 'select:AskUserQuestion', max_results: 1). Все вопросы пользователю — только через AskUserQuestion. По завершении верни done или error."

Agent tool (mode: "auto") — Общие артефакты:
  prompt: "Прочитай файл ${CLAUDE_SKILL_DIR}/references/step-8-common.md и выполни ВСЕ инструкции. Шаблоны: ${CLAUDE_SKILL_DIR}/../../templates/. ПЕРЕД началом работы загрузи AskUserQuestion: ToolSearch(query: 'select:AskUserQuestion', max_results: 1). Все вопросы пользователю — только через AskUserQuestion. По завершении верни done или error."

Agent tool (mode: "auto") — Инфраструктура:
  prompt: "Прочитай файл ${CLAUDE_SKILL_DIR}/references/step-8-infra.md и выполни ВСЕ инструкции. Шаблоны: ${CLAUDE_SKILL_DIR}/../../templates/. ПЕРЕД началом работы загрузи AskUserQuestion: ToolSearch(query: 'select:AskUserQuestion', max_results: 1). Все вопросы пользователю — только через AskUserQuestion. По завершении верни done или error."

Дождись всех. Затем проверь partial failure:

1. Прочитай `gen-report-8-{lang}.json` для КАЖДОГО языка + `gen-report-8-common.json` + `gen-report-8-infra.json`
2. Собери все `failed[]` из всех отчётов
3. Если `failed` пусты → обычный flow:
   ```json
   {"steps": {"8": {"status": "completed"}}, "current_step": 9}
   ```
4. Если есть `failed`:
   a. Загрузи AskUserQuestion: ToolSearch(query: 'select:AskUserQuestion', max_results: 1)
   b. Покажи пользователю:
      question: "Не удалось записать {N} файлов: {список путей}. Что делать?"
      options:
        - {label: "Повторить failed", description: "Перегенерировать только упавшие файлы"}
        - {label: "Пропустить", description: "Продолжить без этих файлов"}
        - {label: "Остановить", description: "Остановить bootstrap"}
   c. "Повторить failed" → запусти ОДИН Agent tool (mode: "auto", sequential) только для failed файлов.
      В prompt передай: конкретный список файлов для повторной генерации, язык, шаблоны.
   d. "Пропустить" → пометь failed в state, продолжай
   e. "Остановить" → ОСТАНОВИСЬ
5. Обнови state.json:
   - `status`: "completed" (всё ок) или "partial" (есть skipped)
   - `failed_files`: [...] (для resume при следующем запуске)

→ `[8/10] Генерация ✓`

### Шаг 9 — CLAUDE.md

Agent tool (mode: "auto"):
  prompt: "Прочитай файл ${CLAUDE_SKILL_DIR}/references/step-9-claude-md.md и выполни ВСЕ инструкции. ПЕРЕД началом работы загрузи AskUserQuestion: ToolSearch(query: 'select:AskUserQuestion', max_results: 1). Все вопросы пользователю — только через AskUserQuestion. По завершении верни done или error."

→ `[9/10] CLAUDE.md ✓`

### Шаг 10 — Финализация

Agent tool (mode: "auto"):
  prompt: "Прочитай файл ${CLAUDE_SKILL_DIR}/references/step-10-finalize.md и выполни ВСЕ инструкции. ПЕРЕД началом работы загрузи AskUserQuestion: ToolSearch(query: 'select:AskUserQuestion', max_results: 1). Все вопросы пользователю — только через AskUserQuestion. По завершении верни done или error."

→ `[10/10] Финализация ✓`

Bootstrap завершён.
