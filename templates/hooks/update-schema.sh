#!/bin/bash
set -uo pipefail
ERR_LOG="${CLAUDE_PROJECT_DIR:-.}/.claude/memory/.hook-errors.log"
trap 'echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] ERROR in $(basename "$0"):$LINENO" >> "$ERR_LOG" 2>/dev/null; exit 0' ERR

PROJECT_DIR="$CLAUDE_PROJECT_DIR"
DB_DIR="$PROJECT_DIR/.claude/database"

COMPOSE_FILE=""
for f in "$PROJECT_DIR/docker-compose.yml" "$PROJECT_DIR/docker-compose.yaml" "$PROJECT_DIR/docker/docker-compose.yml"; do
    [ -f "$f" ] && COMPOSE_FILE="$f" && break
done

if [ -z "$COMPOSE_FILE" ]; then
    exit 0
fi

if [ -f "$DB_DIR/schema.sql" ]; then
    if find "$DB_DIR/schema.sql" -mmin -60 2>/dev/null | grep -q .; then
        exit 0
    fi
fi

mkdir -p "$DB_DIR"

pg_service_name=$(docker compose -f "$COMPOSE_FILE" ps --format json 2>/dev/null | jq -r 'select(.Image | test("postgres")) | .Service' | head -1)
mysql_service_name=$(docker compose -f "$COMPOSE_FILE" ps --format json 2>/dev/null | jq -r 'select(.Image | test("mysql|mariadb")) | .Service' | head -1)

if [ -n "$pg_service_name" ]; then
    PG_CONTAINER=$(docker compose -f "$COMPOSE_FILE" ps -q "$pg_service_name" 2>/dev/null)
    if [ -n "$PG_CONTAINER" ]; then
        DB_NAME=$(docker exec "$PG_CONTAINER" printenv POSTGRES_DB 2>/dev/null || echo "postgres")
        DB_USER=$(docker exec "$PG_CONTAINER" printenv POSTGRES_USER 2>/dev/null || echo "postgres")

        docker exec "$PG_CONTAINER" pg_dump -U "$DB_USER" -d "$DB_NAME" --schema-only --no-owner --no-privileges 2>/dev/null > "$DB_DIR/schema.sql.tmp"
        if [ -s "$DB_DIR/schema.sql.tmp" ]; then
            mv "$DB_DIR/schema.sql.tmp" "$DB_DIR/schema.sql"
        else
            rm -f "$DB_DIR/schema.sql.tmp"
        fi
    fi
fi

if [ -n "$mysql_service_name" ]; then
    MYSQL_CONTAINER=$(docker compose -f "$COMPOSE_FILE" ps -q "$mysql_service_name" 2>/dev/null)
    if [ -n "$MYSQL_CONTAINER" ]; then
        DB_NAME=$(docker exec "$MYSQL_CONTAINER" printenv MYSQL_DATABASE 2>/dev/null || echo "app")
        DB_USER=$(docker exec "$MYSQL_CONTAINER" printenv MYSQL_USER 2>/dev/null || echo "root")
        DB_PASS=$(docker exec "$MYSQL_CONTAINER" printenv MYSQL_PASSWORD 2>/dev/null || docker exec "$MYSQL_CONTAINER" printenv MYSQL_ROOT_PASSWORD 2>/dev/null || echo "")

        docker exec "$MYSQL_CONTAINER" mysqldump -u"$DB_USER" -p"$DB_PASS" --no-data --skip-comments "$DB_NAME" 2>/dev/null > "$DB_DIR/schema.sql.tmp"
        if [ -s "$DB_DIR/schema.sql.tmp" ]; then
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
