# Шаг 2: Определение режима

## Вход
- `.bootstrap-cache/state.json` (из step 1)

## Выход
- `state.mode`: empty | fresh | resume | validate
- Информация о предыдущем bootstrap (если есть)
- Список deprecated файлов для миграции (если validate)

## 2.1 Проверка состояния проекта

Проверь наличие:
1. Директория `.claude/`
2. Файл `.claude/.bootstrap-version` (предыдущий bootstrap)
3. Файл `.bootstrap-cache/state.json` с `current_step > 1` (незавершённый bootstrap)
4. **Стек проекта**: `state.stack.langs` из step-1

## 2.2 Определение режима

```
state.stack.langs пустой И нет манифестов  → empty
Нет .claude/                                → fresh
Есть .bootstrap-cache/state.json (current_step>1) → resume
  + steps[N].status = "in_progress"         → resume с step N
Есть .claude/ + .bootstrap-version          → validate
Есть .claude/ без .bootstrap-version        → validate (legacy)
```

### Режим `empty`

Проект пустой — нет исходного кода, нет манифестов, стек не определён.

1. Создай минимальную структуру:
```bash
mkdir -p .claude/input/tasks .claude/input/plans .claude/memory
```

2. Запиши шаблон спецификации `.claude/input/plans/project-spec.md`:
```markdown
# Спецификация проекта

## Название
{название проекта}

## Описание
{что делает проект, 2-3 предложения}

## Стек
- **Язык:** {php / typescript / python / go / ...}
- **Фреймворк:** {laravel / nestjs / fastapi / gin / ...}
- **БД:** {postgres / mysql / mongo / none}
- **Frontend:** {react / vue / none}
- **Контейнеры:** {docker / none}

## Модули
- {модуль 1 — описание}
- {модуль 2 — описание}

## API
- {endpoint 1}
- {endpoint 2}

## Ограничения и требования
- {требование 1}
- {требование 2}
```

3. Покажи пользователю:

```
[EMPTY PROJECT]
Проект пустой — нет исходного кода и манифестов.
Создан шаблон спецификации: .claude/input/plans/project-spec.md

Заполни спецификацию и запусти /cc-bootstrapper:bootstrap повторно.
Bootstrap подхватит стек из спецификации.
```

4. Установи `state.mode = "empty"`. Переходи к checkpoint. **BOOTSTRAP ЗАВЕРШАЕТСЯ ЗДЕСЬ.**

### Режим `fresh`

Установи `state.mode = "fresh"`. Переходи к checkpoint.

### Режим `resume`

1. Прочитай существующий `.bootstrap-cache/state.json`
2. Найди шаг со статусом `"in_progress"` или первый `"pending"` после последнего `"completed"`
3. Покажи пользователю:

```
Bootstrap прервался на шаге {N}: {название_шага}.
Завершённые шаги: {список completed}
```

4. Используй AskUserQuestion:
- question: "Продолжить с шага {N} или начать заново?"
- options:
  - {label: "Продолжить", description: "Возобновить с шага {N}, сохранённые данные будут использованы"}
  - {label: "Начать заново", description: "Удалить state + cache, начать с нуля"}

Если "Продолжить" → `state.mode = "resume"`, `current_step = N`.
Если "Начать заново" → удалить `.bootstrap-cache/state.json` и `.bootstrap-cache/`, установить `state.mode = "fresh"`, пересоздать state (как в step 1.1).

### Режим `validate`

1. Прочитай `.claude/.bootstrap-version`
2. Определи версию предыдущего bootstrap:
   - Есть поле `version` → показать версию
   - Нет `.bootstrap-version` → `"legacy (pre-v6)"`
3. Покажи пользователю:

```
Обнаружен предыдущий bootstrap v{version}.
Режим: валидация + обновление до v8.0.0.
```

Установи `state.mode = "validate"`.

## 2.3 Детект deprecated файлов (только validate)

Проверь наличие устаревших файлов/структур:

| Deprecated | Замена в v7 | Действие |
|-----------|-------------|----------|
| `.claude/agents/frontend-developer.md` | `{lang}-developer.md` (frontend) | миграция |
| `.claude/agents/frontend-test-developer.md` | `{lang}-test-developer.md` (frontend) | миграция |
| `.claude/agents/frontend-reviewer.md` | `{lang}-reviewer.md` (frontend) | миграция |
| `.claude/agents/frontend-contract.md` | удаляется, функции в analyst | удаление |
| `.claude/agents/{lang}-reviewer-logic.md` | `{lang}-reviewer.md` (объединён) | миграция |
| `.claude/agents/{lang}-reviewer-security.md` | `{lang}-reviewer.md` (объединён) | миграция |
| `.claude/skills/routing/` | `skills/pipeline/` | переименование |
| `.claude/skills/database/` | `skills/storage/` | переименование |
| `.claude/state/` | `.claude/memory/` | миграция (pre-v5.1) |

Если найдены deprecated файлы — покажи:

```
Обнаружены устаревшие файлы:

| Файл | Статус | Действие |
|------|--------|----------|
| agents/frontend-developer.md | deprecated | → миграция в node-developer.md |
| agents/php-reviewer-logic.md | deprecated | → объединение в php-reviewer.md |
| skills/database/ | deprecated | → переименование в storage/ |

Миграция будет выполнена на шаге генерации (step 8).
```

Сохрани список deprecated в `state.deprecated_files[]`:
```json
[
  {"path": "agents/frontend-developer.md", "action": "migrate", "target": "agents/node-developer.md"},
  {"path": "skills/database/", "action": "rename", "target": "skills/storage/"}
]
```

## Лог

**ОБЯЗАТЕЛЬНО** перед checkpoint запиши лог в `.bootstrap-cache/step-2-log.md`:

```markdown
# Step 2: Определение режима — Log

## Выполненные действия
- {что конкретно было сделано, файлы созданные/изменённые}

## Пропущенные действия
- {что было пропущено и почему}

## Ошибки
- {ошибки если были, или "нет"}
```

Записать лог ПЕРЕД checkpoint.

## 2.4 Checkpoint

Обнови `.bootstrap-cache/state.json`:
- `state.mode` → определённый режим
- `steps.2.status` → `"completed"`
- `steps.2.completed_at` → `"{ISO8601}"`
- `current_step` → `3`
- `updated_at` → `"{ISO8601}"`

**Отчёт:** режим ({fresh|resume|validate}), версия предыдущего bootstrap (если validate), количество deprecated файлов (если есть).
