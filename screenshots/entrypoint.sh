#!/usr/bin/env bash
set -euo pipefail

PORT=8090
PG_PORT=8091
DATA_DIR=$(mktemp -d)
PG_DATA_DIR=$(mktemp -d)
EMPTY_DIR="$DATA_DIR/empty"
mkdir -p "$EMPTY_DIR" /output

# Copy test database so the server doesn't modify the original
cp /data/sessions.db "$DATA_DIR/sessions.db"

# ── Start PostgreSQL ─────────────────────────────────────
echo "Starting PostgreSQL..."
PG_DATA="/var/lib/postgresql/data"
PG_USER="agentsview"
PG_DB="agentsview"

# Initialize and start PostgreSQL as the postgres user
su postgres -c "pg_ctlcluster 15 main start" 2>/dev/null || \
  su postgres -c "/usr/lib/postgresql/*/bin/pg_ctl -D /var/lib/postgresql/15/main start -l /tmp/pg.log" 2>/dev/null || \
  {
    # Fallback: initialize fresh cluster
    PG_CLUSTER="/tmp/pgdata"
    mkdir -p "$PG_CLUSTER"
    chown postgres:postgres "$PG_CLUSTER"
    su postgres -c "/usr/lib/postgresql/*/bin/initdb -D $PG_CLUSTER"
    su postgres -c "/usr/lib/postgresql/*/bin/pg_ctl -D $PG_CLUSTER start -l /tmp/pg.log"
  }

# Wait for PG to be ready
for i in $(seq 1 15); do
  if su postgres -c "pg_isready" > /dev/null 2>&1; then
    break
  fi
  sleep 1
done

# Create user and database
su postgres -c "createuser --createdb $PG_USER" 2>/dev/null || true
su postgres -c "createdb -O $PG_USER $PG_DB" 2>/dev/null || true
PG_URL="postgres://$PG_USER@127.0.0.1:5432/$PG_DB?sslmode=disable"

echo "PostgreSQL ready."

# ── Push test data to PostgreSQL ─────────────────────────
echo "Pushing test data to PostgreSQL..."

# Write config with PG settings for the push
cat > "$DATA_DIR/config.toml" <<TOML
[pg]
url = "$PG_URL"
machine_name = "dev-laptop"
allow_insecure = true
TOML

AGENT_VIEWER_DATA_DIR="$DATA_DIR" \
CLAUDE_PROJECTS_DIR="$EMPTY_DIR" \
CODEX_SESSIONS_DIR="$EMPTY_DIR" \
GEMINI_DIR="$EMPTY_DIR" \
agentsview pg push

# Add sessions from a second machine by updating a subset
# directly in PG. This gives the UI multi-machine data so
# machine labels appear on session items.
PGPASSWORD="" psql -U "$PG_USER" -d "$PG_DB" -h 127.0.0.1 <<SQL
SET search_path TO agentsview;
UPDATE sessions
SET machine = 'work-desktop'
WHERE id IN (
  SELECT id FROM sessions
  ORDER BY created_at DESC
  LIMIT (SELECT COUNT(*) / 3 FROM sessions)
);
SQL

echo "PG data ready (two machines)."

# ── Start agentsview (SQLite mode) ───────────────────────
echo "Starting agentsview on port $PORT..."
AGENT_VIEWER_DATA_DIR="$DATA_DIR" \
CLAUDE_PROJECTS_DIR="$EMPTY_DIR" \
CODEX_SESSIONS_DIR="$EMPTY_DIR" \
GEMINI_DIR="$EMPTY_DIR" \
agentsview -port "$PORT" &
SERVER_PID=$!

# ── Start agentsview pg serve ────────────────────────────
echo "Starting agentsview pg serve on port $PG_PORT..."

# Separate data dir for pg serve so it gets its own config
cat > "$PG_DATA_DIR/config.toml" <<TOML
[pg]
url = "$PG_URL"
machine_name = "dev-laptop"
allow_insecure = true
TOML

AGENT_VIEWER_DATA_DIR="$PG_DATA_DIR" \
agentsview pg serve -port "$PG_PORT" &
PG_SERVER_PID=$!

# Wait for both servers to be ready
echo "Waiting for servers..."
for i in $(seq 1 30); do
  SQLITE_OK=false
  PG_OK=false
  if curl -sf "http://127.0.0.1:$PORT/api/v1/stats" > /dev/null 2>&1; then
    SQLITE_OK=true
  fi
  if curl -sf "http://127.0.0.1:$PG_PORT/api/v1/stats" > /dev/null 2>&1; then
    PG_OK=true
  fi
  if $SQLITE_OK && $PG_OK; then
    echo "Both servers ready."
    break
  fi
  if [ "$i" -eq 30 ]; then
    echo "Error: server(s) failed to start (sqlite=$SQLITE_OK, pg=$PG_OK)"
    kill $SERVER_PID 2>/dev/null || true
    kill $PG_SERVER_PID 2>/dev/null || true
    exit 1
  fi
  sleep 1
done

echo ""
echo "Capturing screenshots..."
SCREENSHOT_DIR=/output \
PG_BASE_URL="http://127.0.0.1:$PG_PORT" \
npx playwright test --reporter=list "$@" 2>&1
EXIT_CODE=$?

# Show results
echo ""
if [ -d /output ]; then
  COUNT=$(ls -1 /output/*.png 2>/dev/null | wc -l)
  echo "Captured $COUNT screenshots"
  ls -la /output/*.png 2>/dev/null || true
fi

kill $SERVER_PID 2>/dev/null || true
kill $PG_SERVER_PID 2>/dev/null || true
exit $EXIT_CODE
