---
name: bootstrap
description: Генерирует полную .claude/ структуру автоматизации для любого проекта — агенты, пайплайны, скиллы, memory, hooks, settings. Автоопределение режима fresh/validate/resume.
user-invocable: true
argument-hint: "[meta-prompt-file]"
---

# Bootstrap v7 — Оркестратор

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
  prompt: "Прочитай файл ${CLAUDE_SKILL_DIR}/references/step-1-scan.md и выполни ВСЕ инструкции. Шаблоны: ${CLAUDE_SKILL_DIR}/../../prompts/bootstrap/templates/. ПЕРЕД началом работы загрузи AskUserQuestion: ToolSearch(query: 'select:AskUserQuestion', max_results: 1). Все вопросы пользователю — только через AskUserQuestion. По завершении верни done или error."

→ `[1/10] Сканирование проекта ✓`

### Шаг 2 — Определение режима

Agent tool (mode: "auto"):
  prompt: "Прочитай файл ${CLAUDE_SKILL_DIR}/references/step-2-detect.md и выполни ВСЕ инструкции. ПЕРЕД началом работы загрузи AskUserQuestion: ToolSearch(query: 'select:AskUserQuestion', max_results: 1). Все вопросы пользователю — только через AskUserQuestion. По завершении верни done или error."

→ `[2/10] Определение режима ✓`

### Шаг 3 — Настройка bootstrap

Agent tool (mode: "auto"):
  prompt: "Прочитай файл ${CLAUDE_SKILL_DIR}/references/step-3-configure.md и выполни ВСЕ инструкции. ПЕРЕД началом работы загрузи AskUserQuestion: ToolSearch(query: 'select:AskUserQuestion', max_results: 1). Все вопросы пользователю — только через AskUserQuestion. По завершении верни done или error."

→ `[3/10] Настройка bootstrap ✓`

### Шаг 4 — Settings.json

Agent tool (mode: "auto"):
  prompt: "Прочитай файл ${CLAUDE_SKILL_DIR}/references/step-4-settings.md и выполни ВСЕ инструкции. ПЕРЕД началом работы загрузи AskUserQuestion: ToolSearch(query: 'select:AskUserQuestion', max_results: 1). Все вопросы пользователю — только через AskUserQuestion. По завершении верни done или error."

→ `[4/10] Settings.json ✓`

### Шаг 5 — Плагины и MCP

Agent tool (mode: "auto"):
  prompt: "Прочитай файл ${CLAUDE_SKILL_DIR}/references/step-5-plugins.md и выполни ВСЕ инструкции. ПЕРЕД началом работы загрузи AskUserQuestion: ToolSearch(query: 'select:AskUserQuestion', max_results: 1). Все вопросы пользователю — только через AskUserQuestion. По завершении верни done или error."

→ `[5/10] Плагины и MCP ✓`

### Шаг 6 — План и превью

Agent tool (mode: "auto"):
  prompt: "Прочитай файл ${CLAUDE_SKILL_DIR}/references/step-6-preview.md и выполни ВСЕ инструкции. Шаблоны: ${CLAUDE_SKILL_DIR}/../../prompts/bootstrap/templates/. ПЕРЕД началом работы загрузи AskUserQuestion: ToolSearch(query: 'select:AskUserQuestion', max_results: 1). Все вопросы пользователю — только через AskUserQuestion. По завершении верни done или error."

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
  prompt: "Прочитай файл ${CLAUDE_SKILL_DIR}/references/step-8-lang.md и выполни ВСЕ инструкции для языка {lang}. Шаблоны: ${CLAUDE_SKILL_DIR}/../../prompts/bootstrap/templates/. ПЕРЕД началом работы загрузи AskUserQuestion: ToolSearch(query: 'select:AskUserQuestion', max_results: 1). Все вопросы пользователю — только через AskUserQuestion. По завершении верни done или error."

Agent tool (mode: "auto") — Общие артефакты:
  prompt: "Прочитай файл ${CLAUDE_SKILL_DIR}/references/step-8-common.md и выполни ВСЕ инструкции. Шаблоны: ${CLAUDE_SKILL_DIR}/../../prompts/bootstrap/templates/. ПЕРЕД началом работы загрузи AskUserQuestion: ToolSearch(query: 'select:AskUserQuestion', max_results: 1). Все вопросы пользователю — только через AskUserQuestion. По завершении верни done или error."

Agent tool (mode: "auto") — Инфраструктура:
  prompt: "Прочитай файл ${CLAUDE_SKILL_DIR}/references/step-8-infra.md и выполни ВСЕ инструкции. Шаблоны: ${CLAUDE_SKILL_DIR}/../../prompts/bootstrap/templates/. ПЕРЕД началом работы загрузи AskUserQuestion: ToolSearch(query: 'select:AskUserQuestion', max_results: 1). Все вопросы пользователю — только через AskUserQuestion. По завершении верни done или error."

Дождись всех. После завершения всех трёх — обнови `.bootstrap-cache/state.json`:
```json
{"steps": {"8": {"status": "completed"}}, "current_step": 9}
```

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
