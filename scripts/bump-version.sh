#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

BUMP_TYPE="${1:?Usage: bump-version.sh <major|minor|patch|X.Y.Z> [--dry-run]}"
DRY_RUN="${2:-}"

CURRENT=$(jq -r '.version' "$ROOT_DIR/.claude-plugin/plugin.json")

if [[ "$BUMP_TYPE" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  NEW_VERSION="$BUMP_TYPE"
else
  IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT"
  case "$BUMP_TYPE" in
    major) MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0 ;;
    minor) MINOR=$((MINOR + 1)); PATCH=0 ;;
    patch) PATCH=$((PATCH + 1)) ;;
    *) echo "Error: use major|minor|patch or X.Y.Z"; exit 1 ;;
  esac
  NEW_VERSION="$MAJOR.$MINOR.$PATCH"
fi

echo "Bump: $CURRENT → $NEW_VERSION"
[[ "$DRY_RUN" == "--dry-run" ]] && echo "(dry-run mode)"
echo ""

update_file() {
  local file="$1" rel="${1#$ROOT_DIR/}"
  if [[ "$DRY_RUN" == "--dry-run" ]]; then
    echo "  [DRY] $rel"
  else
    echo "  [OK]  $rel"
  fi
}

# 1. plugin.json
if [[ "$DRY_RUN" != "--dry-run" ]]; then
  jq --arg v "$NEW_VERSION" '.version = $v' "$ROOT_DIR/.claude-plugin/plugin.json" > "$ROOT_DIR/.claude-plugin/plugin.json.tmp" \
    && mv "$ROOT_DIR/.claude-plugin/plugin.json.tmp" "$ROOT_DIR/.claude-plugin/plugin.json"
fi
update_file "$ROOT_DIR/.claude-plugin/plugin.json"

# 2. marketplace.json
if [[ "$DRY_RUN" != "--dry-run" ]]; then
  jq --arg v "$NEW_VERSION" '.plugins[0].version = $v' "$ROOT_DIR/.claude-plugin/marketplace.json" > "$ROOT_DIR/.claude-plugin/marketplace.json.tmp" \
    && mv "$ROOT_DIR/.claude-plugin/marketplace.json.tmp" "$ROOT_DIR/.claude-plugin/marketplace.json"
fi
update_file "$ROOT_DIR/.claude-plugin/marketplace.json"

# 3. Skill templates (YAML frontmatter: version: "X.Y.Z")
for f in "$ROOT_DIR"/templates/skills/*.md; do
  [[ -f "$f" ]] || continue
  if [[ "$DRY_RUN" != "--dry-run" ]]; then
    sed -i "s/^version: \"[0-9]*\.[0-9]*\.[0-9]*\"/version: \"$NEW_VERSION\"/" "$f"
  fi
  update_file "$f"
done

# 4. Pipeline templates (HTML comment: <!-- version: X.Y.Z -->)
for f in "$ROOT_DIR"/templates/pipelines/*.md; do
  [[ -f "$f" ]] || continue
  if [[ "$DRY_RUN" != "--dry-run" ]]; then
    sed -i "s/<!-- version: [0-9]*\.[0-9]*\.[0-9]* -->/<!-- version: $NEW_VERSION -->/" "$f"
  fi
  update_file "$f"
done

# 5. All step files + references (version strings in code/examples)
for f in "$ROOT_DIR"/skills/bootstrap/references/step-*.md; do
  [[ -f "$f" ]] || continue
  if [[ "$DRY_RUN" != "--dry-run" ]]; then
    sed -i "s/--arg version \"[0-9]*\.[0-9]*\.[0-9]*\"/--arg version \"$NEW_VERSION\"/" "$f"
    sed -i "s/version: \"[0-9]*\.[0-9]*\.[0-9]*\"/version: \"$NEW_VERSION\"/g" "$f"
    sed -i "s/<!-- version: [0-9]*\.[0-9]*\.[0-9]* -->/<!-- version: $NEW_VERSION -->/g" "$f"
    sed -i "s/< [0-9]*\.[0-9]*\.[0-9]*/< $NEW_VERSION/g" "$f"
    sed -i "s/до v[0-9]*\.[0-9]*\.[0-9]*/до v$NEW_VERSION/g" "$f"
  fi
  update_file "$f"
done

echo ""
echo "=== Verification ==="
echo -n "plugin.json: "; jq -r '.version' "$ROOT_DIR/.claude-plugin/plugin.json"
echo -n "marketplace: "; jq -r '.plugins[0].version' "$ROOT_DIR/.claude-plugin/marketplace.json"
echo -n "skill sample: "; grep -m1 'version:' "$ROOT_DIR/templates/skills/pipeline.md" 2>/dev/null || echo "n/a"
echo -n "pipeline sample: "; head -1 "$ROOT_DIR/templates/pipelines/new-code.md" 2>/dev/null || echo "n/a"
echo ""
echo "Done. Version bumped to $NEW_VERSION"
[[ "$DRY_RUN" == "--dry-run" ]] && echo "(dry-run, no files changed)" || true
