# Шаг 6: План и превью

> Modes: fresh, upgrade

## Вход
- `state.stack` (из step 1)
- `state.registries` (частичные, из step 3: custom agents/skills/pipelines)

## Выход
- `state.registries` — финальные реестры (agents, skills, pipelines, hooks)
- `state.metrics` — оценка токенов и файлов
- `.claude/.cache/dry-run/preview.md` — сохранённый preview

## 6.1 Формирование финальных реестров

### Агенты

Для КАЖДОГО `{lang}` из `state.stack.langs` — 4 агента:

| Агент | Файл | Условие |
|-------|------|---------|
| {Lang} Architect | `{lang}-architect.md` | всегда |
| {Lang} Developer | `{lang}-developer.md` | всегда |
| {Lang} Test Developer | `{lang}-test-developer.md` | всегда |
| {Lang} Reviewer | `{lang}-reviewer.md` | всегда |

Общие агенты:

| Агент | Файл | Условие |
|-------|------|---------|
| Analyst | `analyst.md` | всегда |
| Storage Architect | `storage-architect.md` | если `state.stack.db` != null |
| DevOps | `devops.md` | всегда |
| QA Engineer | `qa-engineer.md` | всегда |

Кастомные агенты из `state.registries.agents` где `type = "custom"` — добавить как есть.

**Итого:** `len(LANGS) × 4 + общие + кастомные`

Каждый элемент реестра:
```json
{"name": "...", "type": "lang|common|custom", "lang": "...", "file": "...", "status": "pending"}
```

### Скиллы

7 базовых — всегда:

| # | Скилл | Директория |
|---|-------|------------|
| 1 | Code Style | `skills/code-style/` |
| 2 | Architecture | `skills/architecture/` |
| 3 | Storage | `skills/storage/` |
| 4 | Testing | `skills/testing/` |
| 5 | Memory | `skills/memory/` |
| 6 | Pipeline | `skills/pipeline/` |
| 7 | Pipeline Alias | `skills/p/` |

Кастомные скиллы из `state.registries.skills` где `type = "custom"` — добавить как есть.

### Пайплайны

8 базовых — всегда:

| # | Пайплайн | Файл |
|---|----------|------|
| 1 | new-code | `pipelines/new-code.md` |
| 2 | fix-code | `pipelines/fix-code.md` |
| 3 | review | `pipelines/review.md` |
| 4 | tests | `pipelines/tests.md` |
| 5 | full-feature | `pipelines/full-feature.md` |
| 6 | api-docs | `pipelines/api-docs.md` |
| 7 | qa-docs | `pipelines/qa-docs.md` |
| 8 | brainstorm | `pipelines/brainstorm.md` |

Кастомные пайплайны из `state.registries.pipelines` где `type = "custom"` — добавить как есть.

### Хуки

| # | Хук | Файл | Условие |
|---|-----|------|---------|
| 1 | Track Agent | `scripts/hooks/track-agent.sh` | всегда |
| 2 | Maintain Memory | `scripts/hooks/maintain-memory.sh` | всегда |
| 3 | Update Schema | `scripts/hooks/update-schema.sh` | если `state.stack.db` != null |

## 6.2 Оценка токенов

Рассчитай по формулам:

| Категория | Формула |
|-----------|---------|
| Агенты | `count(agents) × 800` |
| Скиллы | `count(skills) × 1500` |
| Пайплайны | `count(pipelines) × 1800` |
| Хуки | `count(hooks) × 350` |
| settings.json | `800` |
| CLAUDE.md | `3000` |
| Memory (facts + patterns + issues) | `500` |
| verify-bootstrap.sh | `400` |
| .bootstrap-manifest.json | `200` |

**Итого:** сумма всех категорий.

Сохрани результат в `state.metrics`:
```json
{
  "agents_count": 0,
  "agents_tokens": 0,
  "skills_count": 0,
  "skills_tokens": 0,
  "pipelines_count": 0,
  "pipelines_tokens": 0,
  "hooks_count": 0,
  "hooks_tokens": 0,
  "other_tokens": 4900,
  "total_files": 0,
  "total_tokens": 0
}
```

## 6.3 Dry-Run Preview

Покажи пользователю ASCII-таблицу:

```
╔══════════════════════════════════════════════════════════╗
║                    DRY-RUN PREVIEW                      ║
╠══════════════════════════════════════════════════════════╣
║  Режим:         {state.mode}                            ║
║  Языки:         {state.stack.langs}                     ║
╠══════════════════════════════════════════════════════════╣
║  Категория          Файлов     Токенов (≈)              ║
║  ─────────────────  ─────────  ──────────               ║
║  Агенты             {count}    {tokens}                  ║
║  Скиллы             {count}    {tokens}                  ║
║  Пайплайны          {count}    {tokens}                  ║
║  Хуки               {count}    {tokens}                  ║
║  Прочее             —          {other_tokens}            ║
╠══════════════════════════════════════════════════════════╣
║  ИТОГО              {total}    ~{total_tokens}           ║
╠══════════════════════════════════════════════════════════╣
║  ⚠ Оценочные output-токены. Фактическая стоимость       ║
║  зависит от глубины анализа и размера проекта.          ║
╚══════════════════════════════════════════════════════════╝
```

При `patch` mode — для каждого файла показать статус: `[OK]` / `[FIX]` / `[NEW]` / `[REGEN]`.

### Подтверждение

Используй AskUserQuestion:
- question: "Продолжить генерацию?"
- header: "Dry-Run"
- options:
  - {label: "Продолжить", description: "Запустить генерацию по плану"}
  - {label: "Скорректировать", description: "Вернуться к настройкам (step 3)"}
  - {label: "Отменить", description: "Прервать bootstrap"}
- multiSelect: false

Если "Скорректировать" → верни `change` оркестратору (он вернётся к Configure).
Если "Отменить" → верни `pause`, оркестратор завершит bootstrap.

## 6.4 Сохранение

1. Записать финальные реестры в `state.registries`
2. Записать метрики в `state.metrics`
3. Сохранить preview в `.claude/.cache/dry-run/preview.md`
4. Обновить `.claude/.cache/_index.md` — добавить секцию `dry-run/`

## Лог

Перед checkpoint запиши лог в `.claude/.cache/step-6-log.md`:

```markdown
# Step 6: План и превью — Log

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
  "steps": {"preview": {"status": "completed", "completed_at": "..."}},
}
```
