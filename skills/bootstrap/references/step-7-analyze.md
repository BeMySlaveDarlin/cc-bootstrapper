# Шаг 7: Глубокий анализ

## Вход
- `.bootstrap-cache/state.json` → `config.analysis_depth`, `stack`
- `.bootstrap-cache/analysis/` (из step 1)

## Выход
- `.bootstrap-cache/deep/` — файлы глубокого анализа
- Обновлённый `.bootstrap-cache/_index.md`

## 7.0 Проверка режима

Если `analysis_depth = "light"`:
→ Вывести: `[7/10] Глубокий анализ [ПРОПУСК — режим light]`
→ Обновить state, перейти к checkpoint
→ НЕ создавать `.bootstrap-cache/deep/`

---

## 7.1 Запуск анализа

Анализ ВСЕГДА выполняется per-domain через под-субагентов.

### Standard-анализ (standard | deep)

**Custom instructions:** Если `state.config.custom_instructions` не null — добавь в конец prompt каждого субагента строку:
`Дополнительные инструкции от пользователя: {config.custom_instructions}`

Для КАЖДОГО `{lang}` из `state.stack.langs` — запусти отдельный Agent tool (mode: "auto"):
  prompt: "Проанализируй {lang}-код проекта в {PROJECT_DIR}.
  Используй Grep/Glob для поиска паттернов, Read для 10-15 репрезентативных файлов.
  НЕ читай все файлы. Определи: naming, error handling, imports, code patterns.

  Сначала оцени свой scope:
  find {PROJECT_DIR} -type f -name '*.{ext}' -not -path '*/vendor/*' -not -path '*/node_modules/*' | wc -l

  Если справляешься (< 500 файлов) — выполни анализ и верни 'done'.
  Если scope слишком большой (500+ файлов) — НЕ делай работу сам. Верни 'need_split' и запиши
  план дробления в .bootstrap-cache/deep/{lang}-split-plan.json:
  {\"status\": \"need_split\", \"scopes\": [
    {\"dir\": \"src/Auth\", \"prompt\": \"Проанализируй {lang}-код в {PROJECT_DIR}/src/Auth. ...\"},
    {\"dir\": \"src/Billing\", \"prompt\": \"...\"}
  ]}

  Запиши результат в .bootstrap-cache/deep/{lang}-patterns.md (если done).
  Вопросы — только через AskUserQuestion."

Запускай per-lang субагентов ПАРАЛЛЕЛЬНО если языков > 1.

**Обработка need_split (оркестратор шага 5, не главный оркестратор):**
Если субагент вернул `need_split`:
1. Прочитай `{lang}-split-plan.json`
2. Для каждого scope из плана — запусти Agent tool (mode: "auto") с промптом из плана
3. После завершения всех — запусти ещё один Agent tool для мержа:
   "Прочитай все файлы .bootstrap-cache/deep/{lang}-*.md и объедини в {lang}-patterns.md"

### Deep-анализ (deep, дополнительно)

Запусти отдельные субагенты per-domain ПАРАЛЛЕЛЬНО через Agent tool (mode: "auto"):

- **Архитектура**: "Проанализируй архитектуру проекта в {PROJECT_DIR}. Модули, слои, DI. Запиши в .bootstrap-cache/deep/architecture.md"
- **API** (если есть): "Проанализируй API проекта в {PROJECT_DIR}. Endpoints, методы, middleware. Запиши в .bootstrap-cache/deep/api-contracts.md"
- **Тесты**: "Проанализируй тесты проекта в {PROJECT_DIR}. Фреймворки, fixtures, покрытие. Запиши в .bootstrap-cache/deep/testing-patterns.md"
- **Инфра** (если контейнеры/CI): "Проанализируй инфру в {PROJECT_DIR}. Docker, CI/CD, deploy. Запиши в .bootstrap-cache/deep/infra.md"
- **Storage** (если есть): "Проанализируй хранилища в {PROJECT_DIR}. Схема, миграции, ORM. Запиши в .bootstrap-cache/deep/storage.md"

Пропусти домен если данных для него нет.

---

## 7.2 Standard-анализ (содержание)

Для КАЖДОГО `{lang}`:

Файл: `.bootstrap-cache/deep/{lang}-patterns.md`

```markdown
# {Lang} — Паттерны кода

## Naming
- Переменные: camelCase | snake_case | ...
- Функции: ...
- Классы: ...
- Файлы: ...

## Error Handling
- Основной паттерн: ...
- Примеры из кода: ...

## Imports
- Стиль: ...
- Алиасы: ...

## Паттерны
- ...
```

---

## 7.3 Deep-анализ (содержание, дополнительно к standard)

### architecture.md
- Модульная структура: модули, слои, границы
- DI: контейнер, провайдеры, биндинги
- Слоение: controller → service → repository

### api-contracts.md
- REST endpoints, HTTP-методы, маршруты, middleware
- GraphQL: схемы, resolvers (если есть)
- gRPC: proto-файлы, сервисы (если есть)
- Пропустить если нет API

### testing-patterns.md
- Структура тестов: unit / integration / e2e
- Fixtures, фабрики данных, моки
- Покрытие: конфиг coverage

### infra.md
- Dockerfile, docker-compose, CI/CD, deploy
- Пропустить если нет контейнеров и CI

### storage.md
- Схема БД, миграции, ORM-паттерны
- Пропустить если нет хранилищ

---

## 7.4 Split-правило

После генерации КАЖДОГО файла — проверить размер.
Если файл > 50K токенов:
1. Разбить на логические части
2. Обновить `_index.md`

---

## 7.5 Обновление индекса

Обновить `.bootstrap-cache/_index.md` — добавить созданные файлы в deep/.

## Лог

**ОБЯЗАТЕЛЬНО** перед checkpoint запиши лог в `.bootstrap-cache/step-7-log.md`:

```markdown
# Step 7: Глубокий анализ — Log

## Выполненные действия
- {что конкретно было сделано, файлы созданные/изменённые}

## Пропущенные действия
- {что было пропущено и почему}

## Ошибки
- {ошибки если были, или "нет"}
```

Записать лог ПЕРЕД checkpoint.

## Checkpoint

Обнови state:
```json
{
  "steps": {"7": {"status": "completed", "completed_at": "..."}},
  "current_step": 8
}
```
