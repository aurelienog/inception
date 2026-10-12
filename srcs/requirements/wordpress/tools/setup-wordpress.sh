#!/bin/sh
set -eu

/usr/local/bin/check-wordpress-config.sh

WORDPRESS_DIR="/var/www/html"
WORDPRESS_SOURCE="/usr/src/wordpress"
PHP_FPM_BIN="/usr/sbin/php-fpm8.2"

# Restrict permissions on temporary files.
umask 077

# Run WP-CLI without printing its output to container logs.
# On failure, show only a generic error to avoid exposing secrets.
run_wp_quiet() {
    log_file=$(mktemp /tmp/wp-cli.XXXXXX)

    if wp "$@" --allow-root >"$log_file" 2>&1; then
        rm -f "$log_file"
        return 0
    else
        status=$?
        rm -f "$log_file"
        echo "ERROR: A WP-CLI operation failed. Details withheld to protect secrets." >&2
        return "$status"
    fi
}

# Initialize WordPress files in the persistent volume.
if [ ! -f "$WORDPRESS_DIR/wp-includes/version.php" ]; then
    echo "Copying WordPress files to the persistent volume..."

    if [ ! -f "$WORDPRESS_SOURCE/wp-includes/version.php" ]; then
        echo "ERROR: WordPress source files are missing." >&2
        exit 1
    fi

    mkdir -p "$WORDPRESS_DIR"
    cp -a "$WORDPRESS_SOURCE"/. "$WORDPRESS_DIR"/
else
    echo "WordPress files already exist."
fi

# Set permissions.
chown -R www-data:www-data "$WORDPRESS_DIR"

# Create wp-config.php if it does not exist.
if [ ! -f "$WORDPRESS_DIR/wp-config.php" ]; then
    echo "Creating WordPress configuration..."

    if ! wp config create \
        --path="$WORDPRESS_DIR" \
        --dbname="$MYSQL_DATABASE" \
        --dbuser="$MYSQL_USER" \
        --dbhost="mariadb" \
        --dbprefix="wp_" \
        --skip-check \
        --prompt=dbpass \
        --allow-root \
        < /run/secrets/db_password \
        >/dev/null 2>&1; then
        echo "ERROR: Could not create wp-config.php." >&2
        exit 1
    fi

    chmod 640 "$WORDPRESS_DIR/wp-config.php"
    chown www-data:www-data "$WORDPRESS_DIR/wp-config.php"
else
    echo "WordPress configuration already exists."
fi

# Configure the public site URL.
run_wp_quiet config set WP_HOME "https://$DOMAIN_NAME" \
    --path="$WORDPRESS_DIR" --type=constant

run_wp_quiet config set WP_SITEURL "https://$DOMAIN_NAME" \
    --path="$WORDPRESS_DIR" --type=constant

run_wp_quiet config set WP_DEBUG false \
    --path="$WORDPRESS_DIR" --raw --type=constant

# Wait for MariaDB to become available.
echo "Checking MariaDB connection..."

DB_READY=0
attempt=1

while [ "$attempt" -le 30 ]; do
    if wp db check --path="$WORDPRESS_DIR" --allow-root >/dev/null 2>&1; then
        DB_READY=1
        break
    fi

    echo "Waiting for MariaDB ($attempt/30)..."
    sleep 1
    attempt=$((attempt + 1))
done

if [ "$DB_READY" -ne 1 ]; then
    echo "ERROR: MariaDB did not become available." >&2
    exit 1
fi

# Install WordPress only if it has not been installed yet.
if ! wp core is-installed --path="$WORDPRESS_DIR" --allow-root >/dev/null 2>&1; then
    echo "Installing WordPress..."

    if ! wp core install \
        --path="$WORDPRESS_DIR" \
        --url="https://$DOMAIN_NAME" \
        --title="Inception WordPress" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --skip-email \
        --prompt=admin_password \
        --allow-root \
        < /run/secrets/wp_admin_password \
        >/dev/null 2>&1; then
        echo "ERROR: WordPress installation failed." >&2
        exit 1
    fi
else
    echo "WordPress is already installed; skipping initial installation."
fi

# Ensure the regular user exists, including after a partially completed setup.
if ! wp user get "$WP_USER" \
    --path="$WORDPRESS_DIR" --allow-root >/dev/null 2>&1; then
    echo "Creating the regular WordPress user..."

    if ! wp user create "$WP_USER" "$WP_USER_EMAIL" \
        --role=subscriber \
        --path="$WORDPRESS_DIR" \
        --prompt=user_pass \
        --allow-root \
        < /run/secrets/wp_user_password \
        >/dev/null 2>&1; then
        echo "ERROR: Could not create the regular WordPress user." >&2
        exit 1
    fi
fi

# Configure PHP-FPM to listen on port 9000.
mkdir -p /run/php

echo "Starting PHP-FPM..."

exec "$PHP_FPM_BIN" -F
