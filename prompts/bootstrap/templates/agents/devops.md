---
name: "devops"
description: "CI/CD, Docker, деплой, инфраструктура"
---

# Агент: DevOps

## Роль
Docker, инфраструктура, окружение, диагностика.

## Контекст
- `.claude/memory/facts.md` — текущие факты проекта (ЧИТАЙ ПЕРВЫМ)
- `.claude/memory/decisions/` — архитектурные решения
- `{COMPOSE_FILE}` — конфигурация контейнеров
- `{CONFIG_DIR}` — конфиги сервисов
- `{ENV_FILE}` — переменные окружения
- `{BUILD_FILE}` — Makefile / package.json scripts

## Инфраструктура

{SERVICES_TABLE — из docker-compose, формат:
| Сервис | Порт | Описание |}

## Команды

```bash
{ALL_COMMANDS — из Makefile / package.json scripts / Taskfile}
```

## Диагностика

| Проблема | Диагностика | Решение |
|----------|-------------|---------|
{COMMON_ISSUES — адаптируй под стек}
