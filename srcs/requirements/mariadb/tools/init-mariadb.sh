#!/bin/sh
set -eu

DATADIR="/var/lib/mysql"
SOCKET="/run/mysqld/mysqld-init.sock"

mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld

if [ ! -d "$DATADIR/mysql" ]; then
    echo "Initializing MariaDB data directory..."

    mariadb-install-db \
        --user=mysql \
        --datadir="$DATADIR" \
        --skip-test-db

    ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
    DB_PASSWORD=$(cat /run/secrets/db_password)

    # Escape single quotes before inserting passwords into SQL.
    ROOT_PASSWORD_SQL=$(printf '%s' "$ROOT_PASSWORD" | sed "s/'/''/g")
    DB_PASSWORD_SQL=$(printf '%s' "$DB_PASSWORD" | sed "s/'/''/g")

    echo "Starting temporary initialization server..."

    gosu mysql mariadbd \
        --skip-networking \
        --skip-grant-tables \
        --socket="$SOCKET" &
    INIT_PID=$!

    cleanup() {
        if kill -0 "$INIT_PID" 2>/dev/null; then
            kill "$INIT_PID" 2>/dev/null || true
            wait "$INIT_PID" 2>/dev/null || true
        fi
    }
    trap cleanup EXIT

    READY=0
    for attempt in $(seq 1 30); do
        if mariadb-admin --protocol=socket \
            --socket="$SOCKET" -u root ping --silent 2>/dev/null; then
            READY=1
            break
        fi
        sleep 1
    done

    if [ "$READY" -ne 1 ]; then
        echo "ERROR: MariaDB initialization server did not start." >&2
        exit 1
    fi

    mariadb --protocol=socket --socket="$SOCKET" -u root <<SQL
FLUSH PRIVILEGES;
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD_SQL}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${ROOT_PASSWORD_SQL}';
SQL

    echo "Stopping temporary initialization server..."
    kill "$INIT_PID"
    wait "$INIT_PID" || true
    trap - EXIT

    unset ROOT_PASSWORD DB_PASSWORD ROOT_PASSWORD_SQL DB_PASSWORD_SQL
fi

echo "Starting MariaDB..."
exec gosu mysql mariadbd