---
name: "pipeline"
description: "Роутер — классифицирует задачу и запускает нужный pipeline"
user-invocable: true
argument-hint: "[описание задачи]"
version: "8.1.0"
---

> **CRITICAL: Имя директории `skills/pipeline/` и файл frontmatter КОПИРОВАТЬ AS-IS.
> НЕ переименовывать в routing/, router/, или другое.
> Имя директории = имя slash-команды `/pipeline`. Изменение = система НЕ РАБОТАЕТ.**

# Pipeline — Единый роутер

Ты — оркестратор. Единый вход для всех операций с кодом.

## Фаза 0: Роутинг

### Шаг 0 — Resume detection

Проверь `.claude/output/state/` — есть ли файлы `*.json`.

Если найден ровно один state файл:
```
AskUserQuestion:
  question: "Найден незавершённый pipeline: {pipeline} ({task-slug}). Завершено {completed}/{total} фаз."
  options:
    - {label: "Продолжить", description: "Возобновить с фазы {next}"}
    - {label: "Заново", description: "Удалить state и начать с нуля"}
    - {label: "Отменить", description: "Ничего не делать"}
```
→ "Продолжить": прочитай `.claude/pipelines/{pipeline}.md` и выполни с учётом state (Phase 0.5 внутри pipeline разберётся)
→ "Заново": удали state файл, продолжай роутинг как обычно
→ "Отменить": ОСТАНОВИСЬ

Если найдено несколько state файлов:
```
AskUserQuestion:
  question: "Найдено несколько незавершённых pipeline-ов:"
  options: {динамически: список pipeline-ов из state файлов + "Начать новый" + "Отменить"}
```

Если state файлов нет — продолжай роутинг.

### Шаг 1 — Контекст
1. Прочитай `.claude/memory/facts.md`
2. Проверь `.claude/memory/decisions/` — релевантные решения

### Шаг 1.5 — Парсинг флагов
Если `$ARGUMENTS` содержит `--no-analysis` или `--skip-analyst`:
- Установи `SKIP_ANALYSIS=true`
- Удали флаг из `$ARGUMENTS` перед классификацией

### Шаг 2 — Классификация
Проанализируй аргумент `$ARGUMENTS` и определи тип:

| Intent | Триггеры |
|--------|----------|
| **NEW-CODE** | новый, добавь, создай, фича, модуль, эндпоинт |
| **FIX-CODE** | баг, ошибка, fix, не работает, сломалось, regression |
| **REVIEW** | ревью, проверь, review, посмотри код |
| **TESTS** | тесты, покрытие, unit test, coverage |
| **API-DOCS** | документация, api docs, контракт |
| **QA-DOCS** | чеклист, QA, postman |
| **FULL-FEATURE** | полный цикл, feature, от начала до конца |
| **HOTFIX** | срочно, hotfix, prod |
| **BRAINSTORM** | обсудим, идея, brainstorm, брейншторм, побрейнштормим, как лучше, варианты, подход, продумать, предложи |
| **FREE** | вопрос, обсуждение, объясни, помоги |
{CUSTOM_PIPELINE_KEYWORDS}

Приоритет: HOTFIX > FULL-FEATURE > явное имя > keyword > спросить.
Если FREE — ответь напрямую, без pipeline.

Если неоднозначно:
AskUserQuestion:
  question: "Не удалось определить тип задачи. Какой pipeline запустить?"
  options:
    - {label: "new-code", description: "Новый модуль, сервис, эндпоинт"}
    - {label: "fix-code", description: "Баг, ошибка, regression"}
    - {label: "review", description: "Ревью кода"}
    - {label: "tests", description: "Написание тестов"}
    - {label: "full-feature", description: "Полный цикл фичи"}
    - {label: "hotfix", description: "Срочное исправление"}
    - {label: "api-docs", description: "API-контракты"}
    - {label: "qa-docs", description: "QA-чеклисты, Postman"}
    - {label: "brainstorm", description: "Мозговой штурм, анализ вариантов"}
    {CUSTOM_PIPELINE_OPTIONS}

### Шаг 3 — Подтверждение

AskUserQuestion:
  question: "[PIPELINE: {TYPE}] {краткое описание задачи}\nПодтвердить?"
  options:
    - {label: "Да", description: "Запустить pipeline"}
    - {label: "Уточнить", description: "Скорректировать задачу или сменить pipeline"}
    - {label: "Отменить", description: "Не запускать"}

### Шаг 3.5 — Анализ задачи (только new-code / full-feature)

Если пайплайн = NEW-CODE или FULL-FEATURE и `SKIP_ANALYSIS` не установлен:

AskUserQuestion:
  question: "Запустить анализ задачи? Аналитик задаст уточняющие вопросы и сформирует ТЗ."
  options:
    - {label: "Да", description: "Аналитик изучит код, схему и сформирует ТЗ"}
    - {label: "Пропустить", description: "Сразу к архитектуре без анализа"}

Если "Пропустить" → `SKIP_ANALYSIS=true`

### Шаг 3.6 — Контекст задачи

Для NEW-CODE / FULL-FEATURE — пропустить (аналитик или architect разберутся сами).

Для FIX-CODE / HOTFIX:

AskUserQuestion:
  question: "Тип проблемы?"
  options:
    - {label: "Runtime error", description: "Ошибка при выполнении"}
    - {label: "Logic bug", description: "Неверная бизнес-логика"}
    - {label: "Data issue", description: "Проблема с данными"}
    - {label: "Performance", description: "Медленная работа"}

AskUserQuestion:
  question: "Где проявляется?"
  options: {динамически из facts.md → Key Paths + "Other"}
  multiSelect: true

Для TESTS:

AskUserQuestion:
  question: "Тип тестов?"
  options:
    - {label: "Unit", description: "Unit-тесты для классов/функций"}
    - {label: "Integration", description: "Интеграционные тесты"}
    - {label: "Coverage gap", description: "Покрыть непокрытые участки"}

AskUserQuestion:
  question: "Целевые модули?"
  options: {динамически из facts.md → Key Paths + "Other"}
  multiSelect: true

Для REVIEW / API-DOCS / QA-DOCS — без дополнительных вопросов.

### Шаг 4 — Диспатч
Прочитай `.claude/pipelines/{type}.md` и выполни ВСЕ фазы.

