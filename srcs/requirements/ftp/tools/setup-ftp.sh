#!/bin/sh
set -eu

: "${FTP_USER:?FTP_USER is required}"
: "${FTP_PASV_ADDRESS:?FTP_PASV_ADDRESS is required}"
: "${FTP_PASV_MIN_PORT:?FTP_PASV_MIN_PORT is required}"
: "${FTP_PASV_MAX_PORT:?FTP_PASV_MAX_PORT is required}"

FTP_PASSWORD_FILE="/run/secrets/ftp_password"
FTP_ROOT="/var/www/html"

if [ ! -s "$FTP_PASSWORD_FILE" ]; then
    echo "ERROR: FTP password secret is missing or empty." >&2
    exit 1
fi

# Validate the FTP username.
case "$FTP_USER" in
    ""|*[!a-zA-Z0-9_-]*)
        echo "ERROR: Invalid FTP_USER." >&2
        exit 1
        ;;
esac

# Validate the passive port range.
case "$FTP_PASV_MIN_PORT:$FTP_PASV_MAX_PORT" in
    *[!0-9:]*)
        echo "ERROR: Passive ports must be numeric." >&2
        exit 1
        ;;
esac

if [ "$FTP_PASV_MIN_PORT" -lt 1024 ] ||
   [ "$FTP_PASV_MAX_PORT" -gt 65535 ] ||
   [ "$FTP_PASV_MIN_PORT" -gt "$FTP_PASV_MAX_PORT" ]; then
    echo "ERROR: Invalid passive port range." >&2
    exit 1
fi

# Validate the advertised IPv4 address.
if ! printf '%s\n' "$FTP_PASV_ADDRESS" |
    grep -Eq '^([0-9]{1,3}\.){3}[0-9]{1,3}$'; then
    echo "ERROR: FTP_PASV_ADDRESS must be an IPv4 address." >&2
    exit 1
fi

# Wait for WordPress to create its persistent directory.
if [ ! -d "$FTP_ROOT" ]; then
    echo "ERROR: WordPress volume is not mounted." >&2
    exit 1
fi

# Create a dedicated login sharing the www-data filesystem identity.
# The duplicate UID is intentional: it gives FTP the same file
# ownership permissions as PHP-FPM without making files world-writable.
if ! id "$FTP_USER" >/dev/null 2>&1; then
    useradd \
        --non-unique \
        --uid "$(id -u www-data)" \
        --gid "$(id -g www-data)" \
        --home-dir "$FTP_ROOT" \
        --shell /bin/bash \
        "$FTP_USER"
fi

# Configure the password from the mounted Docker secret.
FTP_PASSWORD=$(cat "$FTP_PASSWORD_FILE")

if [ -z "$FTP_PASSWORD" ]; then
    echo "ERROR: FTP password secret is empty." >&2
    exit 1
fi

printf '%s:%s\n' "$FTP_USER" "$FTP_PASSWORD" | chpasswd
unset FTP_PASSWORD

mkdir -p /var/run/vsftpd/empty
chmod 0555 /var/run/vsftpd/empty
# Configure vsftpd in foreground mode for proper container lifecycle.
cat > /etc/vsftpd.conf <<EOF
listen=YES
listen_ipv6=NO
background=NO

anonymous_enable=NO
local_enable=YES
write_enable=YES

local_umask=002
file_open_mode=0666

chroot_local_user=YES
allow_writeable_chroot=YES
local_root=$FTP_ROOT

use_localtime=YES
xferlog_enable=YES
connect_from_port_20=YES

pasv_enable=YES
pasv_min_port=$FTP_PASV_MIN_PORT
pasv_max_port=$FTP_PASV_MAX_PORT
pasv_address=$FTP_PASV_ADDRESS
pasv_addr_resolve=NO

pam_service_name=vsftpd
secure_chroot_dir=/var/run/vsftpd/empty
EOF

echo "Starting vsftpd..."

exec /usr/sbin/vsftpd /etc/vsftpd.conf