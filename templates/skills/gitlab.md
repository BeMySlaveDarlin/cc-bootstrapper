---
name: "gitlab"
description: "MCP-интеграция с GitLab: маппинг операций на MCP tools"
user-invocable: false
condition: "config.gitlab_mcp"
---

# Skill: GitLab MCP — Маппинг операций

## Merge Requests
| Операция | Tool | Обязательные параметры |
|----------|------|----------------------|
| Создать MR | mcp__gitlab__create_merge_request | projectId, sourceBranch, targetBranch, title |
| Получить MR | mcp__gitlab__get_merge_request | projectId, mergeRequestIid |
| Список MR | mcp__gitlab__list_merge_requests | projectId |
| Approve MR | mcp__gitlab__approve_merge_request | projectId, mergeRequestIid |
| Merge MR | mcp__gitlab__merge_merge_request | projectId, mergeRequestIid |
| Diff MR | mcp__gitlab__get_merge_request_diffs | projectId, mergeRequestIid |

## Issues
| Операция | Tool | Обязательные параметры |
|----------|------|----------------------|
| Создать issue | mcp__gitlab__create_issue | projectId, title |
| Получить issue | mcp__gitlab__get_issue | projectId, issueIid |
| Список issues | mcp__gitlab__list_issues | projectId |
| Мои issues | mcp__gitlab__list_issues | scope=assigned_to_me |

## Pipelines
| Операция | Tool | Обязательные параметры |
|----------|------|----------------------|
| Список | mcp__gitlab__list_pipelines | projectId |
| Retry | mcp__gitlab__retry_pipeline | projectId, pipelineId |
| Cancel | mcp__gitlab__cancel_pipeline | projectId, pipelineId |

## Wiki
| Операция | Tool | Обязательные параметры |
|----------|------|----------------------|
| Список страниц | mcp__gitlab__list_wiki_pages | projectId |
| Получить страницу | mcp__gitlab__get_wiki_page | projectId, slug |
| Создать страницу | mcp__gitlab__create_wiki_page | projectId, title, content |

## Типовые сценарии

### Создание MR
1. `mcp__gitlab__create_merge_request` (projectId, sourceBranch, targetBranch, title, description)
2. Проверить ответ → вернуть URL

### Ревью MR
1. `mcp__gitlab__get_merge_request` → получить метаданные
2. `mcp__gitlab__get_merge_request_diffs` → получить diff
3. Анализ кода
4. `mcp__gitlab__create_merge_request_note` → оставить комментарий

## Обработка ошибок

| Код | Причина | Действие |
|-----|---------|----------|
| 401 | Невалидный токен | Проверить GITLAB_PERSONAL_ACCESS_TOKEN в .mcp.json |
| 403 | Недостаточно прав | Проверить permissions пользователя |
| 404 | Неверный projectId/IID | Проверить параметры |
| 409 | Конфликт | MR уже существует или branch conflict |

## Правила
- Деструктивные операции (delete, merge) — требуют подтверждения пользователя
- Не логировать токен
