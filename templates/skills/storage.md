---
name: "storage"
description: "Паттерны работы с хранилищами данных: БД, кэш, очереди, object storage"
user-invocable: false
---

# Skill: Storage — {PROJECT_NAME}

## Primary Database

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

## Cache (условная секция, если CACHE != none)

- Тип: {CACHE_TYPE} (Redis/Memcached/...)
- Driver: {CACHE_DRIVER}
- Конфиг: {CACHE_CONFIG_PATH}
- Паттерны: {CACHE_PATTERNS} (cache-aside, write-through, TTL policy)
- Именование ключей: {CACHE_KEY_NAMING} (например `{entity}:{id}:{field}`)

## Queue (условная секция, если QUEUE != none)

- Тип: {QUEUE_TYPE} (RabbitMQ/Kafka/SQS/...)
- Driver: {QUEUE_DRIVER}
- Конфиг: {QUEUE_CONFIG_PATH}
- Именование: {QUEUE_NAMING} (exchanges, queues, topics)

## Object Storage (условная секция, если OBJECT_STORAGE != none)

- Тип: {OBJECT_STORAGE_TYPE} (S3/MinIO/GCS/...)
- Конфиг: {OBJECT_STORAGE_CONFIG_PATH}
- Именование buckets: {BUCKET_NAMING}

## Именование

| Элемент | Конвенция | Пример |
|---------|-----------|--------|
| Таблицы | {TABLE_NAMING} | {TABLE_EXAMPLE} |
| Столбцы | {COLUMN_NAMING} | {COLUMN_EXAMPLE} |
| FK | {FK_NAMING} | {FK_EXAMPLE} |
| Индексы | {INDEX_NAMING} | {INDEX_EXAMPLE} |
| Cache ключи | {CACHE_KEY_NAMING} | {CACHE_KEY_EXAMPLE} |
| Queue имена | {QUEUE_NAMING} | {QUEUE_EXAMPLE} |
| Buckets | {BUCKET_NAMING} | {BUCKET_EXAMPLE} |

## Антипаттерны

{STORAGE_ANTIPATTERNS}
