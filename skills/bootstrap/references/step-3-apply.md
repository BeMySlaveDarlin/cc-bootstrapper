# Шаг 3B: Настройка bootstrap — Применение

> **SUBAGENT ISOLATION:** Этот шаг выполняется как изолированный субагент.

## Роль

Ты — применитель. Получаешь готовые ответы от оркестратора. **НЕ задаёшь вопросов.** Парсишь данные, записываешь в state.

## Вход

Данные передаются в prompt от оркестратора как JSON:

```json
{
  "features": ["Custom agents", "Custom skills"],
  "analysis_depth": "standard",
  "custom_instructions": null,
  "permissions_level": "balanced",
  "git_permissions": ["Read", "Write"],
  "custom_agents": [{"name": "api-documenter", "role": "Генерация API-документации из кода"}],
  "custom_skills": [{"name": "caching", "description": "Паттерны кеширования данных"}],
  "custom_pipelines": []
}
```

## Парсинг ответов

### features (из вопроса "Конфигурация")
- Массив выбранных label: `["Custom agents", "Custom skills", "Custom pipelines"]`
- Если пустой/Enter → `[]`

### analysis_depth (из вопроса "Анализ")
- `"light"` | `"standard (рекомендуется)"` → `"standard"` | `"deep"`
- Нормализуй: убери " (рекомендуется)" из label
- Если значение не совпадает с preset labels — fuzzy-match (fallback):
  - "standart", "стандарт", "стандартный", "средний" → "standard"
  - "глубокий", "полный", "full", "максимальный" → "deep"
  - "лёгкий", "легкий", "быстрый", "fast", "lite" → "light"
  - Не распознано → "standard"

### custom_instructions (из оркестратора)
- Строка с дополнительными пользовательскими инструкциями
- Если не задано или `null` → `null`
- Передаётся как есть — НЕ интерпретировать

### permissions_level (из вопроса "Permissions")
- `"conservative"` | `"balanced (рекомендуется)"` → `"balanced"` | `"permissive"`
- Нормализуй аналогично

### git_permissions (из вопроса "Git")
- Массив label: `["Read", "Write", "Push", "Delete"]`
- Нормализуй в lowercase: `["read", "write", "push", "delete"]`

### custom_agents
- Preset label (api-documenter и т.д.) → роль из description
- Other формат `name=роль` → парси
- Other без `=` → role = "auto"

### custom_skills
- Preset label → description из option
- Other формат `name=описание` → парси

### custom_pipelines
- Preset label → trigger и agents определяются автоматически
- Для каждого: `{name, trigger: "auto", agents: "auto"}`

## Значения по умолчанию

Если опция НЕ выбрана в features:
| Опция | Default |
|-------|---------|
| custom_agents | `[]` |
| custom_skills | `[]` |
| custom_pipelines | `[]` |

## Запись в state

Обнови `.bootstrap-cache/state.json`:

```json
{
  "config": {
    "features": [...],
    "analysis_depth": "standard",
    "custom_instructions": null,
    "permissions_level": "balanced",
    "git_permissions": ["read", "write"],
    "custom_agents": [{"name": "...", "role": "..."}],
    "custom_skills": [{"name": "...", "description": "..."}],
    "custom_pipelines": [{"name": "...", "trigger": "...", "agents": [...]}]
  },
  "steps": {
    "3": {
      "status": "completed",
      "completed_at": "{ISO8601}"
    }
  },
  "current_step": 4,
  "updated_at": "{ISO8601}"
}
```

## Лог

Запиши `.bootstrap-cache/step-3-log.md`:

```markdown
# Step 3: Настройка bootstrap — Log

## Конфигурация
- Глубина анализа: {analysis_depth}
- Permissions: {permissions_level}
- Git: {git_permissions}
- Custom agents: {count}
- Custom skills: {count}
- Custom pipelines: {count}
```

Верни `done`.
