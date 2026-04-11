# Шаг 3A: Настройка bootstrap — Сбор данных

> Modes: fresh, upgrade

> **SUBAGENT ISOLATION:** Этот шаг выполняется как изолированный субагент.

## Роль

Ты — сборщик. Читаешь state, рассчитываешь estimates, формируешь структуру вопросов для оркестратора. **НЕ задаёшь вопросов пользователю. НЕ пишешь в state.**

## Вход
- `.claude/.cache/state.json` (stack + mode из step 1-2)

## Выход

Верни JSON-блок с двумя секциями:

```json
{
  "questions_main": {
    "questions": [
      {
        "question": "Какие опции включить? (Enter — базовая конфигурация)",
        "header": "Конфигурация",
        "options": [
          {"label": "Custom agents", "description": "Добавить кастомных агентов помимо базовых по стеку"},
          {"label": "Custom skills", "description": "Добавить кастомные скиллы"},
          {"label": "Custom pipelines", "description": "Добавить кастомные пайплайны"}
        ],
        "multiSelect": true
      },
      {
        "question": "Глубина анализа проекта?",
        "header": "Анализ",
        "options": [
          {"label": "light", "description": "Только manifest + структура (уже выполнен, +0 tokens)"},
          {"label": "standard (рекомендуется)", "description": "+ паттерны кода, naming conventions (~{ESTIMATE_STANDARD} tokens)"},
          {"label": "deep", "description": "+ архитектура, API-контракты, test coverage (~{ESTIMATE_DEEP} tokens)"}
        ],
        "multiSelect": false
      },
      {
        "question": "Уровень permissions для settings.json?",
        "header": "Permissions",
        "options": [
          {"label": "conservative", "description": "Только read-операции: Bash(git status/log/diff), Read, Glob, Grep"},
          {"label": "balanced (рекомендуется)", "description": "+ lint/test команды, language tools (composer, npm, pip, cargo)"},
          {"label": "permissive", "description": "+ docker, git write (add/commit/push), deploy-скрипты"}
        ],
        "multiSelect": false
      },
      {
        "question": "Какие git-операции разрешить?",
        "header": "Git",
        "options": [
          {"label": "Read", "description": "git status, git log, git diff, git show, git branch (рекомендуется)"},
          {"label": "Write", "description": "git add, git commit"},
          {"label": "Push", "description": "git push, git pull, git fetch"},
          {"label": "Delete", "description": "git reset, git checkout --, git clean, git branch -D"}
        ],
        "multiSelect": true
      }
    ]
  },
  "questions_followup": {
    "custom_agents": {
      "base_agents": ["php-architect", "php-developer", "..."],
      "question": {
        "question": "Какие кастомные агенты добавить?\n\nЧерез Other: name=роль, name=роль\nНапример: api-documenter=Генерация API-документации",
        "header": "Custom agents",
        "options": [
          {"label": "api-documenter", "description": "Генерация API-документации из кода"},
          {"label": "migration-manager", "description": "Управление миграциями БД и данных"},
          {"label": "performance-engineer", "description": "Оптимизация производительности, профилирование"}
        ],
        "multiSelect": true
      }
    },
    "custom_skills": {
      "base_skills": ["code-style", "architecture", "storage", "testing", "memory", "pipeline", "p"],
      "question": {
        "question": "Какие кастомные скиллы добавить?\n\nЧерез Other: name=описание, name=описание",
        "header": "Custom skills",
        "options": [
          {"label": "caching", "description": "Паттерны кеширования данных"},
          {"label": "notifications", "description": "Паттерны отправки уведомлений"},
          {"label": "logging", "description": "Стандарты логирования"},
          {"label": "monitoring", "description": "Паттерны мониторинга и метрик"},
          {"label": "queue", "description": "Паттерны очередей и async-обработки"}
        ],
        "multiSelect": true
      }
    },
    "custom_pipelines": {
      "base_pipelines": ["new-code", "fix-code", "review", "tests", "api-docs", "qa-docs", "full-feature", "brainstorm"],
      "question": {
        "question": "Какие кастомные пайплайны добавить?",
        "header": "Pipelines",
        "options": [
          {"label": "deploy", "description": "Деплой на окружение"},
          {"label": "seed-data", "description": "Генерация тестовых данных"},
          {"label": "generate-types", "description": "Генерация TypeScript типов из API"},
          {"label": "migration", "description": "Создание и применение миграций БД"}
        ],
        "multiSelect": true
      }
    }
  },
  "estimates": {
    "standard": 12345,
    "deep": 45678
  },
  "stack_summary": {
    "langs": ["php", "js"],
    "file_count": 150,
    "has_ci": true,
    "has_db": true
  }
}
```

## Логика

1. Прочитай `.claude/.cache/state.json`
2. Из `state.stack` извлеки: langs, file_count, CI detection, DB detection
3. Рассчитай estimates:
   ```
   LANG_COUNT = количество языков
   FILE_COUNT = количество исходных файлов
   ESTIMATE_STANDARD = LANG_COUNT * 3000 + min(FILE_COUNT, 50) * 200
   ESTIMATE_DEEP = LANG_COUNT * 8000 + min(FILE_COUNT, 200) * 300
   ```
4. Подставь estimates в описания options для вопроса "Глубина анализа"
5. Сформируй `base_agents` на основе langs: `{lang}-architect`, `{lang}-developer`, `{lang}-test-developer`, `{lang}-reviewer` для каждого lang + `analyst`, `devops`, `qa-engineer` + `storage-architect` (если has_db) + `ci-manager` (если has_ci)
6. Верни JSON-блок и слово `done`

## Правило skip

Если `state.config.analysis_depth` существует (config реально заполнен) — верни `skip`. Пустой `{}` — не skip.
