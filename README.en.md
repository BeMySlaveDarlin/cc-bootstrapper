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
/install-plugin cc-bootstrapper
```

The plugin registers the `/cc-bootstrapper:bootstrap` skill automatically.

### Manual Installation (legacy)

```bash
# Copy meta-prompt and templates
cp prompts/meta-prompt-bootstrap.md ~/.claude/prompts/
cp -r prompts/bootstrap ~/.claude/prompts/

# Create a command that invokes the meta-prompt
mkdir -p ~/.claude/commands
cat > ~/.claude/commands/bootstrap.md << 'EOF'
Read and execute all steps from `~/.claude/prompts/meta-prompt-bootstrap.md` for the current project.
EOF
```

## Usage

```bash
cd /path/to/your-project
claude
```
```
> /cc-bootstrapper:bootstrap    # Plugin mode
> /bootstrap                    # Legacy mode (manual install)
```

Auto-detection: no `.claude/` → full generation, existing `.claude/` → validation + auto-fix.

Supported stacks: PHP, Node.js/TypeScript, Python, Go, Rust, Java, C#, Ruby. Multi-language projects get agent sets for each language.

---

# Generated System

Everything below describes what appears in the target project after `/bootstrap` and how to work with it.

## Routing

CLAUDE.md contains a HARD RULE: any code-related request is automatically routed through `/pipeline`. Free-form is only for questions and discussions.

```
/pipeline review          → code review
/p fix auth bug           → fix-code pipeline
/p new users endpoint     → new-code pipeline
/p                        → determines type from context
```

The router classifies the task by keywords, then gathers context via AskUserQuestion. For `new-code`/`full-feature` it offers to run analysis (analyst creates a spec); for others — scope/problem type + affected modules. `--no-analysis` flag skips analysis.

## Pipelines

8 base pipelines + custom ones (added during bootstrap):

| Pipeline | When | Key Phases |
|----------|------|------------|
| `new-code` | New module, service, endpoint | Analysis → Architecture → DB → Code → Tests → Review |
| `fix-code` | Bug, error, regression | Diagnosis → Fix → Tests → Review |
| `review` | Code review | Parallel Review (logic + security) → Report |
| `tests` | Writing tests | Analyze → Generate → Verify → Review |
| `api-docs` | API contracts | Scan → Generate → Save |
| `qa-docs` | Checklists, Postman | Input → Checklist → Postman → Save |
| `full-feature` | Full feature cycle | new-code + api-docs + qa-docs |
| `hotfix` | Urgent fix | fix-code + review |

### Data Passing Between Phases

Phases exchange data through files, not conversation context:

```
Analyst    → reads code and infra, asks questions, writes spec to output/plans/{task-slug}-spec.md
Architect  → reads spec, writes plan to output/plans/{task-slug}.md
Developer  → reads plan from file, writes code
Tester     → reads code (git diff), writes tests
Reviewers  → read code (git diff), write reports to output/reviews/{task-slug}-{type}.md
```

Only a summary (5-10 lines per phase) returns to the pipeline context. Full results are available to the next agent via file reading.

### Plan Mode

- Analyst works in PLAN MODE + READ-ONLY — reads code/schema/infra, asks clarifying questions, creates spec
- Architect works in PLAN MODE — analysis only, plan shown for approval, no project file modifications
- `fix-code` and `tests` request plan confirmation via AskUserQuestion before execution

### CAPTURE

Each pipeline ends with a CAPTURE phase — memory update:
- `facts.md` updated by section (Stack, Key Paths, Active Decisions, Known Issues)
- New decisions → `decisions/{date}-{slug}.md`
- Patterns → `patterns.md`
- Bugs → `issues.md`

### Adaptive Teams

`new-code`, `review`, `full-feature` support parallel mode:
- **Opus 4.6** → reviewers work in parallel via Teams API
- **Other models** → automatic fallback to sequential mode

## Agents

Self-contained markdown files. Each agent reads its own context (facts.md, decisions/, skills/); from the pipeline it only receives task-slug and input data path.

For each language — 5 agents:

| Agent | Role | Mode |
|-------|------|------|
| `{lang}-architect` | Module planning and architecture | PLAN MODE (read-only) |
| `{lang}-developer` | Writing code from plan | Writes files |
| `{lang}-test-developer` | Writing tests | Writes files |
| `{lang}-reviewer-logic` | Business logic review | READ-ONLY |
| `{lang}-reviewer-security` | Security review | READ-ONLY |

Shared agents: `analyst`, `db-architect`, `devops`, `frontend-developer`, `frontend-test-developer`, `frontend-reviewer`, `qa-engineer`.

Agent sections: Role → Mode → Context (self-read) → Input → Task → Rules → Output.

## Skills

Knowledge bases that agents read during work:

| Skill | Contents |
|-------|----------|
| `code-style/` | Code patterns and anti-patterns for the project |
| `architecture/` | Module structure, DI, routes |
| `database/` | Migrations, data types, indexes |
| `testing/` | Test framework, mocks, test structure |
| `memory/` | Rules for working with the memory system |
| `pipeline/` | `/pipeline` router (invocable) |
| `p/` | `/p` alias for quick access (invocable) |

## Memory

| File | Purpose | Limits |
|------|---------|--------|
| `facts.md` | Stack, paths, active decisions, known issues | Sectional updates, 10 issues max |
| `patterns.md` | Recurring code patterns | — |
| `issues.md` | Known issues from reviews | 30 lines, deduplication by Frequency |
| `decisions/*.md` | Architectural decisions (ADR-lite) | 20 active max |
| `decisions/archive/` | Outdated decisions | Auto-rotation 30 days |

Agents read `facts.md` by section (Stack, Key Paths, Active Decisions) — not the entire file.

Pipelines update `facts.md` by section with REPLACE/MERGE semantics, not appending. Deduplication before adding.

## Hooks

| Hook | Event | What It Does |
|------|-------|------------|
| `track-agent.sh` | PostToolUse (Task) | Logs agent usage to `usage.jsonl` |
| `maintain-memory.sh` | SessionStart | Rotates decisions, compacts facts/issues, cleans output/ older than 7 days |
| `update-schema.sh` | SessionStart (if DB) | Updates `database/schema.sql` from Docker |

## Output

| Directory | Contents | Lifecycle |
|-----------|----------|-----------|
| `output/plans/` | Architect plans | Auto-cleanup after 7 days |
| `output/reviews/` | Review reports | Auto-cleanup after 7 days |
| `output/contracts/` | API contracts | Permanent |
| `output/qa/` | QA checklists, Postman | Permanent |

## GitLab MCP (optional)

If configured during bootstrap — `.mcp.json` with GitLab MCP server + `gitlab-manager` agent + `gitlab` pipeline:
- Manage Issues, MRs, Pipelines, Wiki
- Router automatically directs requests like "create MR", "issue #42"

## Customization

The entire structure is yours after generation.

**Agent:** create `.claude/agents/{name}.md` following existing structure, add to CLAUDE.md, connect to pipeline.

**Skill:** `mkdir -p .claude/skills/{name}`, create `SKILL.md`. For invocable — frontmatter `user-invocable: true`.

**Pipeline:** create `.claude/pipelines/{name}.md` (minimum 2 phases with Task()), add keywords to `skills/pipeline/SKILL.md`, add to CLAUDE.md.

**Hook:** create `.claude/scripts/hooks/{name}.sh`, `chmod +x`, add to `settings.json`.

## License

[MIT](LICENSE)
