# cc-bootstrapper

[Русский](README.md)

Automation bootstrap generator for Claude Code. Run `/cc-bootstrapper:bootstrap` in any project — get a complete `.claude/` structure: agents, pipelines, skills, memory, hooks, settings. Then work through `/pipeline`.

## Requirements

- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code)
- Bash 4+
- `jq`
- macOS, Linux, or Windows (WSL)

## Installation

### As a Claude Code Plugin (recommended)

In Claude Code CLI:
```
/plugin marketplace add BeMySlaveDarlin/cc-bootstrapper
/plugin install cc-bootstrapper@bemyslavedarlin-cc-bootstrapper
```

### Local Installation (for development)

```
/plugin marketplace add /path/to/cc-bootstrapper
/plugin install cc-bootstrapper@bemyslavedarlin-cc-bootstrapper
```

## Usage

```
/cc-bootstrapper:bootstrap
```

If Agent Teams are available — prompts for mode: **Team** (parallel agents, ~x2 faster) or **Sequential** (one-by-one, more stable).

Auto-detection:
- Empty project → generates spec template, stops early
- No `.claude/` → full generation (fresh)
- Existing `.claude/` → validation + migration (validate)
- Existing state → resume from last step

Supported stacks: PHP, Node.js/TypeScript, Python, Go, Rust, Java, C#, Ruby. Multi-language projects get agent sets for each language.

## Bootstrap Process (10 steps)

| Step | Name | What It Does |
|------|------|------------|
| 1 | Scan | Light scan: manifests, structure, stack, git remote |
| 2 | Detect Mode | empty / fresh / validate / resume |
| 3 | Configure | permissions, git, analysis depth, custom agents/skills/pipelines |
| 4 | Settings.json | Base permissions + hooks |
| 5 | Plugins & MCP | Playwright, Context7, LSP, GitLab/GitHub/Docker MCP |
| 6 | Preview | Dry-run preview, token estimates, **pause point** |
| 7 | Deep Analysis | Per-lang patterns, architecture, API (optional) |
| 8 | Generation | Per-domain in parallel: per-lang + common + infra |
| 9 | CLAUDE.md | Generation with agent/skill/pipeline tables |
| 10 | Finalization | Verification, .bootstrap-version, cleanup |

**Team mode:** phases A(scan∥) → B(config) → C(preview) → D(gen∥) → E(finalize∥). Per-lang generation in parallel via TeamCreate.

Each step is an isolated subagent. Data passes through `.bootstrap-cache/state.json`. On crash — resume from last step.

---

# Generated System

Everything below describes what appears in the target project after bootstrap and how to work with it.

## Routing

CLAUDE.md contains a HARD RULE: any code-related request is routed through `/pipeline`.

```
/pipeline review          → code review
/p fix auth bug           → fix-code pipeline
/p new users endpoint     → new-code pipeline
/p brainstorm approach    → brainstorm pipeline
/p                        → determines type from context
```

## Pipelines

9 base pipelines + custom ones. Pipelines have YAML frontmatter with triggers, error_routing, adaptive_teams.

| Pipeline | When | Key Phases | Agent Teams |
|----------|------|------------|-------------|
| `new-code` | New module, service, endpoint | Analysis → Architecture → Storage → Code → Tests → Review | developer + test-developer + reviewer |
| `fix-code` | Bug, error, regression | Diagnosis → Fix → Tests → Review | developer + test-developer + reviewer |
| `review` | Code review | Per-lang Review → Report | reviewers per-lang ∥ |
| `tests` | Writing tests | Analyze → Generate → Verify → Review | test-developer + reviewer |
| `brainstorm` | Discuss idea, approach | Frame → Perspectives → Capture | analyst ∥ architect ∥ storage ∥ devops |
| `api-docs` | API contracts | Scan → Generate → Save | — |
| `qa-docs` | Checklists, Postman, E2E | Input → Checklist → Automation → Save | — |
| `full-feature` | Full feature cycle | new-code + api-docs + qa-docs | — (chains) |
| `hotfix` | Urgent fix | fix-code + review | — (chains) |

5 pipelines support **Agent Teams**: TeamCreate → Agent spawn → SendMessage coordination → TeamDelete. Automatic fallback to sequential.

### Data Passing Between Phases

Phases exchange data through files, not conversation context:

```
Analyst    → spec in output/plans/{task-slug}-spec.md
Architect  → plan in output/plans/{task-slug}.md
Developer  → code from plan
Tester     → tests from code (git diff)
Reviewer   → report in output/reviews/{task-slug}-{lang}.md
```

Agents **write artifacts to file first, then return summary**. On crash, artifacts are preserved.

### CAPTURE

Each pipeline ends with a CAPTURE phase — memory update:
- `facts.md` updated by section (Stack, Key Paths, Active Decisions, Known Issues)
- New decisions → `decisions/{date}-{slug}.md`
- Patterns → `patterns.md`
- Bugs → `issues.md`

## Agents

For each language — 4 agents:

| Agent | Role | Mode |
|-------|------|------|
| `{lang}-architect` | Module planning and architecture | plan (read-only) |
| `{lang}-developer` | Writing code from plan | implement |
| `{lang}-test-developer` | Writing tests | implement |
| `{lang}-reviewer` | Full review: architecture, logic, security, static analysis, optimization | plan (read-only) |

Shared agents:

| Agent | Role | Condition |
|-------|------|-----------|
| `analyst` | Task decomposition, specs | always |
| `storage-architect` | Storage design: SQL, NoSQL, Redis, S3, queues | if storage detected |
| `devops` | Docker, CI/CD, host machine (WSL/Linux/macOS), deploy | always |
| `qa-engineer` | Test plans, checklists, Postman, Playwright E2E, smoke tests | always |

## Skills

| Skill | Contents | Condition |
|-------|----------|-----------|
| `code-style/` | Code patterns and anti-patterns | always |
| `architecture/` | Module structure, DI, routes | always |
| `storage/` | Storage: DB, cache, queues, object storage | always |
| `testing/` | Test framework, mocks, E2E | always |
| `memory/` | Memory system rules | always |
| `pipeline/` | `/pipeline` router (invocable) | always |
| `p/` | `/p` alias (invocable) | always |
| `gitlab/` | GitLab MCP operations: MR, issues, pipelines, wiki | gitlab MCP |
| `github/` | GitHub CLI: PR, issues, actions, releases | github MCP |
| `playwright/` | Playwright MCP: navigation, forms, screenshots, E2E | playwright plugin |

## Memory

| File | Purpose | Limits |
|------|---------|--------|
| `facts.md` | Stack, paths, active decisions, known issues | Sectional updates, 10 issues max |
| `patterns.md` | Recurring code patterns | — |
| `issues.md` | Known issues from reviews | 30 lines, deduplication |
| `decisions/*.md` | Architectural decisions (ADR-lite) | 20 active max |
| `decisions/archive/` | Outdated decisions | Auto-rotation 30 days |

## Hooks

| Hook | Event | What It Does |
|------|-------|------------|
| `track-agent.sh` | PostToolUse (Task/Agent) | Logs agent usage to `usage.jsonl` |
| `maintain-memory.sh` | SessionStart | Rotates decisions, compacts memory, cleans output/ |
| `update-schema.sh` | SessionStart (if DB) | Updates `database/schema.sql` from Docker |

## Plugins & MCP (step 5)

Bootstrap suggests relevant plugins and MCP servers:

| Type | What | Condition |
|------|------|-----------|
| Plugin | Playwright | Frontend or E2E tests |
| Plugin | Context7 | Popular framework |
| Plugin | LSP (TypeScript, PHP, Python, Go) | Per-lang |
| MCP | GitLab | git hosting = GitLab |
| MCP | GitHub | git hosting = GitHub |
| MCP | Docker | Docker in stack |

After installation, permissions are automatically added to settings.json.

## Customization

**Agent:** create `.claude/agents/{name}.md`, add to CLAUDE.md, connect in pipeline.

**Skill:** `mkdir -p .claude/skills/{name}`, create `SKILL.md`. For invocable — `user-invocable: true`.

**Pipeline:** create `.claude/pipelines/{name}.md`, add keywords to `skills/pipeline/SKILL.md`.

**Hook:** create `.claude/scripts/hooks/{name}.sh`, `chmod +x`, add to `settings.json`.

## License

[MIT](LICENSE)
