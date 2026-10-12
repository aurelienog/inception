#!/bin/sh
set -eu

# Check required environment variables
: "${MYSQL_DATABASE:?MYSQL_DATABASE is required}"
: "${MYSQL_USER:?MYSQL_USER is required}"
: "${DOMAIN_NAME:?DOMAIN_NAME is required}"
: "${WP_ADMIN_USER:?WP_ADMIN_USER is required}"
: "${WP_ADMIN_EMAIL:?WP_ADMIN_EMAIL is required}"
: "${WP_USER:?WP_USER is required}"
: "${WP_USER_EMAIL:?WP_USER_EMAIL is required}"

# Check required secrets
for secret in \
    /run/secrets/db_password \
    /run/secrets/wp_admin_password \
    /run/secrets/wp_user_password
do
    if [ ! -s "$secret" ]; then
        echo "ERROR: Required secret is missing or empty: $secret" >&2
        exit 1
    fi
done

# Validate administrator username
ADMIN_USER_LOWER=$(printf '%s' "$WP_ADMIN_USER" | tr '[:upper:]' '[:lower:]')

case "$ADMIN_USER_LOWER" in
    *admin*)
        echo "ERROR: WP_ADMIN_USER must not contain 'admin'." >&2
        exit 1
        ;;
esac

# Validate domain name
case "$DOMAIN_NAME" in
    *[!a-zA-Z0-9.-]*|'')
        echo "ERROR: DOMAIN_NAME contains invalid characters." >&2
        exit 1
        ;;
esac

# Validate database name and user
case "$MYSQL_DATABASE$MYSQL_USER" in
    *[!a-zA-Z0-9_]*|'')
        echo "ERROR: Invalid MYSQL_DATABASE or MYSQL_USER." >&2
        exit 1
        ;;
esac

echo "WordPress configuration checks passed."

