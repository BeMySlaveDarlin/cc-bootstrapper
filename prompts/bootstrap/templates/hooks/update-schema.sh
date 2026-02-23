#!/bin/bash
set -uo pipefail
ERR_LOG="${CLAUDE_PROJECT_DIR:-.}/.claude/memory/.hook-errors.log"
trap 'echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] ERROR in $(basename "$0"):$LINENO" >> "$ERR_LOG" 2>/dev/null; exit 0' ERR

PROJECT_DIR="$CLAUDE_PROJECT_DIR"
DB_DIR="$PROJECT_DIR/.claude/database"
LOCK_FILE="$DB_DIR/.update-lock"

if [ -f "$LOCK_FILE" ]; then
    LOCK_AGE=$(( $(date +%s) - $(stat -c %Y "$LOCK_FILE" 2>/dev/null || echo 0) ))
    if [ "$LOCK_AGE" -lt 30 ]; then
        exit 0
    fi
fi

mkdir -p "$DB_DIR"
touch "$LOCK_FILE"
trap "rm -f '$LOCK_FILE'" EXIT

COMPOSE_FILE=""
for f in "$PROJECT_DIR/docker-compose.yml" "$PROJECT_DIR/docker-compose.yaml" "$PROJECT_DIR/docker/docker-compose.yml"; do
    [ -f "$f" ] && COMPOSE_FILE="$f" && break
done

if [ -z "$COMPOSE_FILE" ]; then
    rm -f "$LOCK_FILE"
    exit 0
fi

ERR_LOG="$PROJECT_DIR/.claude/memory/.hook-errors.log"

pg_service_name=$(awk '/^\s+\S+:/{svc=$1} /image:.*postgres/{gsub(/:$/,"",svc); print svc; exit}' "$COMPOSE_FILE" 2>/dev/null)
mysql_service_name=$(awk '/^\s+\S+:/{svc=$1} /image:.*(mysql|mariadb)/{gsub(/:$/,"",svc); print svc; exit}' "$COMPOSE_FILE" 2>/dev/null)

if [ -n "$pg_service_name" ]; then
    PG_CONTAINER=$(cd "$PROJECT_DIR" && docker compose ps -q "$pg_service_name" 2>/dev/null)
    if [ -n "$PG_CONTAINER" ]; then
        DB_NAME=$(grep -oP 'POSTGRES_DB=\K\S+' "$PROJECT_DIR/.env" 2>/dev/null || grep -oP 'POSTGRES_DB:\s*\K\S+' "$COMPOSE_FILE" 2>/dev/null || echo "postgres")
        DB_USER=$(grep -oP 'POSTGRES_USER=\K\S+' "$PROJECT_DIR/.env" 2>/dev/null || grep -oP 'POSTGRES_USER:\s*\K\S+' "$COMPOSE_FILE" 2>/dev/null || echo "postgres")

        docker exec "$PG_CONTAINER" pg_dump -U "$DB_USER" -d "$DB_NAME" --schema-only --no-owner --no-privileges 2>"$ERR_LOG" > "$DB_DIR/schema.sql.tmp"
        if [ $? -eq 0 ] && [ -s "$DB_DIR/schema.sql.tmp" ]; then
            mv "$DB_DIR/schema.sql.tmp" "$DB_DIR/schema.sql"
        else
            rm -f "$DB_DIR/schema.sql.tmp"
        fi
    fi
fi

if [ -n "$mysql_service_name" ]; then
    MYSQL_CONTAINER=$(cd "$PROJECT_DIR" && docker compose ps -q "$mysql_service_name" 2>/dev/null)
    if [ -n "$MYSQL_CONTAINER" ]; then
        DB_NAME=$(grep -oP 'MYSQL_DATABASE=\K\S+' "$PROJECT_DIR/.env" 2>/dev/null || echo "app")
        DB_USER=$(grep -oP 'MYSQL_USER=\K\S+' "$PROJECT_DIR/.env" 2>/dev/null || echo "root")
        DB_PASS=$(grep -oP 'MYSQL_PASSWORD=\K\S+' "$PROJECT_DIR/.env" 2>/dev/null || grep -oP 'MYSQL_ROOT_PASSWORD=\K\S+' "$PROJECT_DIR/.env" 2>/dev/null || echo "")

        docker exec "$MYSQL_CONTAINER" mysqldump -u"$DB_USER" -p"$DB_PASS" --no-data --skip-comments "$DB_NAME" 2>"$ERR_LOG" > "$DB_DIR/schema.sql.tmp"
        if [ $? -eq 0 ] && [ -s "$DB_DIR/schema.sql.tmp" ]; then
            mv "$DB_DIR/schema.sql.tmp" "$DB_DIR/schema.sql"
        else
            rm -f "$DB_DIR/schema.sql.tmp"
        fi
    fi
fi

for mig_dir in "$PROJECT_DIR/database/migrations" "$PROJECT_DIR/migrations" "$PROJECT_DIR/src/migrations" "$PROJECT_DIR/db/migrations"; do
    if [ -d "$mig_dir" ]; then
        ls -1 "$mig_dir" > "$DB_DIR/migrations.txt" 2>/dev/null
        break
    fi
done

exit 0
