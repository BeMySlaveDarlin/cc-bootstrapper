---
name: "database"
description: "Паттерны работы с БД, миграции, запросы"
user-invocable: false
---

# Skill: Database — {DB_TYPE}

## Подключение

- Тип: {DB_TYPE} {DB_VERSION}
- ORM/Driver: {ORM_NAME}
- Конфиг: {DB_CONFIG_PATH}

## Миграции

- Формат: {MIGRATION_FORMAT}
- Директория: {MIGRATION_DIR}
- Команды:
  - Создать: `{MIGRATION_CREATE_CMD}`
  - Применить: `{MIGRATION_RUN_CMD}`
  - Откатить: `{MIGRATION_ROLLBACK_CMD}`
  - Статус: `{MIGRATION_STATUS_CMD}`

## Типы столбцов

| Назначение | Тип | Пример |
|------------|-----|--------|
{COLUMN_TYPES_TABLE}

## Индексы

{INDEX_RULES}

## Именование

| Элемент | Конвенция | Пример |
|---------|-----------|--------|
| Таблицы | {TABLE_NAMING} | {TABLE_EXAMPLE} |
| Столбцы | {COLUMN_NAMING} | {COLUMN_EXAMPLE} |
| FK | {FK_NAMING} | {FK_EXAMPLE} |
| Индексы | {INDEX_NAMING} | {INDEX_EXAMPLE} |

## Антипаттерны

{DB_ANTIPATTERNS}
