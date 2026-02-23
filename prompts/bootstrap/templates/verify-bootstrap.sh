#!/bin/bash

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
EXIT_CODE=0

echo "=== Checking .claude/ structure ==="
for dir in agents skills pipelines scripts/hooks memory memory/sessions memory/decisions memory/decisions/archive output output/contracts output/qa input database; do
    if [ -d "$PROJECT_DIR/.claude/$dir" ]; then
        echo "[OK] .claude/$dir/"
    else
        echo "[MISS] .claude/$dir/"
        EXIT_CODE=1
    fi
done

echo ""
echo "=== Checking agents ==="
for f in "$PROJECT_DIR"/.claude/agents/*.md; do
    [ -f "$f" ] && echo "[OK] $(basename "$f")"
done

echo ""
echo "=== Checking skills ==="
for f in "$PROJECT_DIR"/.claude/skills/*/SKILL.md; do
    [ -f "$f" ] && echo "[OK] $f"
done

echo ""
echo "=== Pipeline Skill ==="
[ -d "$PROJECT_DIR/.claude/skills/pipeline" ] && echo "[OK] skills/pipeline/" || { echo "[ERR] skills/pipeline/ NOT FOUND"; EXIT_CODE=1; }
[ -d "$PROJECT_DIR/.claude/skills/routing" ] && echo "[ERR] skills/routing/ — устаревшее имя, переименуй в pipeline/"
head -5 "$PROJECT_DIR/.claude/skills/pipeline/SKILL.md" 2>/dev/null | grep -q "user-invocable: true" && echo "[OK] frontmatter" || { echo "[ERR] Missing user-invocable: true in pipeline/SKILL.md"; EXIT_CODE=1; }

[ -d "$PROJECT_DIR/.claude/skills/p" ] && echo "[OK] skills/p/" || echo "[WARN] skills/p/ not found"

grep -q "/pipeline" "$PROJECT_DIR/CLAUDE.md" 2>/dev/null && echo "[OK] /pipeline reference in CLAUDE.md" || { echo "[ERR] CLAUDE.md missing /pipeline reference"; EXIT_CODE=1; }

echo ""
echo "=== Checking pipelines ==="
for f in "$PROJECT_DIR"/.claude/pipelines/*.md; do
    [ -f "$f" ] && echo "[OK] $(basename "$f")"
done

echo ""
echo "=== Checking hooks ==="
for f in "$PROJECT_DIR"/.claude/scripts/hooks/*.sh; do
    if [ ! -f "$f" ]; then continue; fi
    if [ -x "$f" ]; then
        echo "[OK] $(basename "$f") (executable)"
    else
        echo "[WARN] $(basename "$f") (not executable)"
        chmod +x "$f"
        echo "[FIXED] $(basename "$f")"
    fi
    bash -n "$f" 2>/dev/null && echo "  [OK] syntax" || echo "  [ERR] syntax error"
done

echo ""
echo "=== Checking settings ==="
for f in "$PROJECT_DIR"/.claude/settings.json; do
    if [ -f "$f" ]; then
        if jq empty "$f" 2>/dev/null; then
            echo "[OK] $(basename "$f") (valid JSON)"
        else
            echo "[ERR] $(basename "$f") (invalid JSON)"
            EXIT_CODE=1
        fi
    else
        echo "[MISS] $(basename "$f")"
    fi
done

echo ""
echo "=== Checking CLAUDE.md ==="
if [ -f "$PROJECT_DIR/CLAUDE.md" ]; then
    echo "[OK] CLAUDE.md exists"
    for section in "## Agents" "## Skills" "## Pipelines" "## Commands" "## Architecture"; do
        if grep -q "$section" "$PROJECT_DIR/CLAUDE.md"; then
            echo "  [OK] $section"
        else
            echo "  [WARN] Missing: $section"
        fi
    done
else
    echo "[ERR] CLAUDE.md not found"
    EXIT_CODE=1
fi

echo ""
echo "=== Checking memory ==="
for f in "$PROJECT_DIR"/.claude/memory/facts.md "$PROJECT_DIR"/.claude/memory/patterns.md "$PROJECT_DIR"/.claude/memory/issues.md "$PROJECT_DIR"/.claude/skills/memory/SKILL.md; do
    if [ -f "$f" ]; then
        echo "[OK] $(basename "$f")"
    else
        echo "[MISS] $(basename "$f")"
    fi
done
[ -d "$PROJECT_DIR/.claude/memory/decisions" ] && echo "[OK] memory/decisions/" || echo "[MISS] memory/decisions/"

echo ""
echo "=== Summary ==="
echo "Agents: $(ls -1 "$PROJECT_DIR"/.claude/agents/*.md 2>/dev/null | wc -l)"
echo "Skills: $(ls -1d "$PROJECT_DIR"/.claude/skills/*/SKILL.md 2>/dev/null | wc -l)"
echo "Pipelines: $(ls -1 "$PROJECT_DIR"/.claude/pipelines/*.md 2>/dev/null | wc -l)"
echo "Hooks: $(ls -1 "$PROJECT_DIR"/.claude/scripts/hooks/*.sh 2>/dev/null | wc -l)"

exit $EXIT_CODE
