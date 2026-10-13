# Developer Documentation

## 1. Purpose

This document describes the development environment, configuration, build process, service implementation, networking, persistent storage and troubleshooting procedures for the Inception project.

The project uses Docker Compose to orchestrate three services:

- **NGINX:** handles incoming HTTPS requests and forwards PHP requests to WordPress.
- **WordPress:** runs the website using PHP-FPM and communicates with MariaDB.
- **MariaDB:** stores the application's persistent database.

This document focuses on the technical implementation and maintenance of the project.

For an overview of the architecture and the main technical decisions, see [`README.md`](README.md).

For instructions on using the website and its administrative interface, see [`USER_DOC.md`](USER_DOC.md).

## 2. Prerequisites

The development environment requires:

- A Linux virtual machine.
- Docker Engine.
- Docker Compose, using the `docker compose` command.
- GNU Make.
- Git.
- Internet access to download packages during image builds.

Docker must be running, and the current user must have permission to execute Docker commands.

Verify the installed tools:

```bash
docker --version
docker compose version
make --version
git --version
```

Check that Docker is running:

```bash
docker info
```

The current user must have permission to execute Docker commands.

## 3. Environment Configuration

### Environment Variables

The environment file is located at `srcs/.env`.

It contains non-sensitive configuration values used by the application and database services.

It must define the following variables:

| Variable | Purpose |
|---|---|
| `DOMAIN_NAME` | Domain name used by the website |
| `MYSQL_DATABASE` | WordPress database name |
| `MYSQL_USER` | Database application user |
| `WP_ADMIN_USER` | WordPress administrator username |
| `WP_ADMIN_EMAIL` | WordPress administrator email |
| `WP_USER` | Regular WordPress username |
| `WP_USER_EMAIL` | Regular WordPress user email |

The Makefile checks that these variables exist and are not empty before starting the infrastructure.

Inspect the resolved configuration:
```
docker compose -f srcs/docker-compose.yml config
```

**Security note:** The resolved configuration can contain sensitive values if the Compose file interpolates them. Review the output before sharing or saving it.

To check the Compose configuration without starting services:

```bash
docker compose -f srcs/docker-compose.yml config -q
```

### Secrets

Passwords are stored separately from the environment configuration.

```
secrets/
├── db_root_password.txt
├── db_password.txt
├── wp_admin_password.txt
└── wp_user_password.txt
```

Their intended purposes are:

| Secret | Purpose |
|---|---|
| `db_root_password` | MariaDB root account password. |
| `db_password` | Password for the application database account. |
| `wp_admin_password` | WordPress administrator password. |
| `wp_user_password` | Password for the regular WordPress account. |

The Compose configuration declares these files as file-backed Docker secrets and makes the relevant secrets available to each service.

MariaDB receives:
- db_root_password
- db_password

WordPress receives:
- db_password
- wp_admin_password
- wp_user_password

### Protect secret files

Create the secret directory if necessary:
```
mkdir -p secrets
```

Create the required password files using a secure method appropriate to your environment.
Restrict their permissions:
```
chmod 600 secrets/db_root_password.txt
chmod 600 secrets/db_password.txt
chmod 600 secrets/wp_admin_password.txt
chmod 600 secrets/wp_user_password.txt
```

File-backed Docker Compose secrets should not be treated as encrypted secret storage. Protect the source files and restrict access to the host.

Changing a secret file after a service has initialized does not automatically update a password already stored in MariaDB or WordPress.

The Makefile checks that each required secret file exists and is non-empty:

```bash
make check-secrets
```

The Makefile does not validate password strength, file permissions or whether the passwords match accounts already stored in an initialized database.

### Git protection

The root `.gitignore` should exclude local configuration and secrets:

```gitignore
secrets/
srcs/.env
```

Confirm that these files are not tracked by Git:

```bash
git status --short
git check-ignore secrets/db_root_password.txt srcs/.env
```

Never commit passwords or other sensitive credentials. Do not place them in Dockerfiles, scripts, documentation or committed configuration files.

If a secret is accidentally committed, deleting the file in a later commit is not sufficient to remove it from Git history. Rotate the affected credential and follow the repository's cleanup procedure.

## 4. Architecture

The project is orchestrated through `srcs/docker-compose.yml`.

The Compose configuration defines three services, one bridge network and two persistent volumes.

| Service | Image tag | Container name | Published ports | Purpose |
|---|---|---|---|---|
| NGINX | `nginx:1.0` | `nginx` | `443:443` | HTTPS web server |
| WordPress | `wordpress:1.0` | `wordpress` | None | PHP application |
| MariaDB | `mariadb:1.0` | `mariadb` | None | Database server |

The image tags identify the images built for the project. The `container_name` settings assign explicit names to the containers.

Each service is built from its own context:

| Service | Build context |
|---|---|
| NGINX | `./requirements/nginx` |
| WordPress | `./requirements/wordpress` |
| MariaDB | `./requirements/mariadb` |

All services use:
```
restart: always
```

This configures Docker to restart a container when it exits, subject to Docker's restart policy. It does not guarantee that the application is healthy or ready to process requests.

### Startup dependencies

NGINX declares a dependency on WordPress:

```
depends_on:
  - wordpress
```

This establishes the startup order between those services.

However, short-form `depends_on` does not guarantee that PHP-FPM is ready to handle requests when NGINX starts.

The current Compose configuration does not declare a startup dependency between WordPress and MariaDB. WordPress must therefore handle database startup delays and temporary connection failures appropriately.

### Validate Compose configuration

Run:
```
docker compose -f srcs/docker-compose.yml config -q
```

This checks the Compose configuration without starting the containers.
If validation fails, review the reported configuration errors before attempting to build or start the services.

## 5. NGINX Service

NGINX is the public entry point of the application. It receives HTTPS requests, serves static resources and forwards PHP requests to WordPress through FastCGI.

### Build configuration
The NGINX image is built from:
```
srcs/requirements/nginx/
```
The Dockerfile and NGINX configuration define the packages, files and runtime behavior of the service.

### HTTPS and port publishing

The Compose configuration publishes:
```
ports:
  - "443:443"
```

This maps host port 443 to port 443 inside the container.

NGINX handles HTTPS using the **TLS certificate and private key** configured in its server configuration.

When investigating startup failures, verify that the configured certificate and private key exist, are readable and are valid for the configuration.

### Shared WordPress volume

NGINX mounts the WordPress volume at:
```
/var/www/html
```

The mount is read-only:
```
volumes:
  - wordpress:/var/www/html:ro
```

This allows NGINX to read the website files without granting it write access through this mount.

The WordPress service mounts the same volume with write access, allowing the application to manage its files.

### FastCGI communication

NGINX does not execute PHP itself. PHP-FPM handles PHP execution inside the WordPress container.

If PHP-FPM listens on port 9000, the NGINX configuration can forward PHP requests using:
```
fastcgi_pass wordpress:9000;
```

The hostname `wordpress` refers to the Compose service name and is resolved through Docker's internal DNS.

Port 9000 does not need to be published on the host for communication between these services.

### WordPress routing

A common WordPress routing directive is:
```
try_files $uri $uri/ /index.php?$args;
```

NGINX first checks whether the requested path corresponds to an existing file or directory. If neither exists, it internally routes the request to `index.php`, preserving the query arguments.

This allows WordPress to process application routes such as individual pages and posts.

The actual behavior depends on the complete NGINX configuration.

### Validate NGINX

If the container is running, validate the configuration:
```
docker compose -f srcs/docker-compose.yml exec nginx nginx -t
```

Inspect the logs:
```
docker compose -f srcs/docker-compose.yml logs --tail=100 nginx
```

If NGINX fails to start or PHP requests fail, check:
- NGINX configuration syntax.
- TLS certificate and private key paths.
- File permissions.
- The WordPress service name and PHP-FPM listening port.
- FastCGI parameters and script paths.
- Shared network connectivity.
- WordPress file permissions and routing rules.

## 6. WordPress Service

WordPress runs the website application and communicates with MariaDB to store and retrieve application data.

PHP-FPM manages the PHP processes that execute WordPress code.
**NGINX forwards PHP requests to PHP-FPM through FastCGI.**

### Build configuration

The WordPress image is built from:
```
srcs/requirements/wordpress/
```

The Dockerfile and initialization scripts define how WordPress, PHP and PHP-FPM are installed and configured.

### Environment configuration

WordPress loads configuration from `srcs/.env`.

The Compose configuration provides the environment file to the container.

The variables consumed by WordPress depend on the initialization scripts and application configuration included in the image.

Database connection settings must agree with the configuration of the MariaDB service.

### Secrets

WordPress receives the following secrets:
```
db_password
wp_admin_password
wp_user_password
```

The application scripts must read the corresponding secret files and use them when configuring the database connection and WordPress accounts.

The database password must match the password configured for the application account in MariaDB.

### Persistent application files

WordPress mounts the wordpress volume at:
```
/var/www/html
```

The mount is writable:
```
volumes:
  - wordpress:/var/www/html
```

This allows the application files to persist outside the container's writable layer.

NGINX mounts the same volume read-only, allowing it to serve the website files without modifying them through its own mount.

The host directory backing this volume is:
```
/home/aunoguei/data/wordpress
```

### Database connectivity

WordPress connects to MariaDB over the shared Docker network.

The database endpoint is:
```
Host: mariadb
Port: 3306
```

The application should use the Compose service name rather than a hard-coded container IP address.

The configured database name, username and password must match the database configuration.

### Inspect WordPress

Read the service logs:
```
docker compose -f srcs/docker-compose.yml logs --tail=100 wordpress
```

If the website cannot connect to MariaDB, verify the database hostname, database name, username, password and secret mounts.

If NGINX returns gateway errors for PHP requests, verify that PHP-FPM is running and listening on the expected port.

If application files cannot be written, inspect the ownership and permissions of the persistent WordPress directory.

## 7. MariaDB Service

MariaDB provides persistent relational database storage for WordPress.
It stores application data such as users, posts, pages, settings and other database records.

### Build configuration

The MariaDB image is built from:
```
srcs/requirements/mariadb/
```

The Dockerfile defines the image, installed packages and entrypoint configuration.

The initialization script is located in the build context at:
```
srcs/requirements/mariadb/tools/init-mariadb.sh
```

The Dockerfile copies the script into the image for execution when the container starts.

### Environment configuration

MariaDB receives its non-sensitive configuration from `srcs/.env`

The initialization script uses environment variables including:
```
MYSQL_DATABASE
MYSQL_USER
```

These values define the application database and its database account.
The database configuration must remain consistent with the WordPress connection settings.

### Secrets

MariaDB receives two secrets:
```
db_root_password
db_password
```

Their mounted paths are:
```
/run/secrets/db_root_password
/run/secrets/db_password
```

The initialization script reads these files when configuring a new database.

Changing a secret file after the database has been initialized does not automatically update the corresponding database account password.

### Persistent database storage

MariaDB mounts the mariadb volume at:
```
/var/lib/mysql
```

The volume is backed by the host directory:
```
/home/aunoguei/data/mariadb
```

The database files therefore persist independently of the lifecycle of the container.

The host directory must be writable by the MariaDB process running inside the container.

### Initialization process

The entrypoint script handles initial database setup and starts the normal database server.

The initialization process checks whether the database data directory has already been initialized. In the current implementation, the check uses:
```
/var/lib/mysql/mysql
```

For a fresh data directory, the script performs the following operations:
1. Prepares the MariaDB runtime directory.
2. Initializes the MariaDB system tables.
3. Reads the root and application passwords from the mounted secret files.
4. Starts a temporary MariaDB server with TCP networking disabled and grant-table checks skipped.
5. Connects to the temporary server through a Unix socket.
6. Executes the SQL statements required to configure the application database and account.
7. Configures the root account password.
8. Stops the temporary server.
9. Starts the normal MariaDB server.

The exact SQL statements and error-handling behavior are implemented in `init-mariadb.sh`.

### Temporary server

The temporary server allows the initialization script to execute SQL statements against a running database before the normal server starts.

A Unix socket provides local client-server communication without exposing a TCP listener during this initialization phase.

After the initial configuration is complete, the temporary server is stopped.

### Process management

The final command in the initialization script is:
```
exec gosu mysql mariadbd
```

`gosu` switches to the dedicated Linux `mysql` account before starting MariaDB.
`exec` replaces the shell process with `mariadbd`, allowing the database server to become the container's main process.

The database server must remain in the foreground so that the container stays running.

### Existing database data

Once initialized, the database directory is reused during subsequent starts.
Rebuilding the image or recreating the container should not require deleting the database volume.
Changing environment variables or secret files does not automatically reconfigure credentials already stored in an existing database.
Before troubleshooting authentication failures, distinguish between the current secret files and the credentials stored in MariaDB.

### Inspect MariaDB

Read the logs:
```
docker compose -f srcs/docker-compose.yml logs --tail=100 mariadb
```

Check the service status:
```
docker compose -f srcs/docker-compose.yml ps -a
```

Inspect the data directory:
```
ls -ldn /home/aunoguei/data/mariadb
```

If MariaDB fails to start, investigate missing secrets, invalid environment configuration, ownership and permission errors, and SQL initialization failures before considering any destructive operation.

## 8. Networking

The project defines a dedicated bridge network:
```
networks:
  inception:
    driver: bridge
```

All three services are attached to this network.
Docker provides internal DNS resolution, allowing containers to reach other services through their Compose service names.

### Service communication

| Source | Destination | Purpose |
|---|---|---|
| NGINX | WordPress | Forward PHP requests to PHP-FPM. |
| WordPress | MariaDB | Read and write application data. |

The expected internal endpoints are:

| Service | Internal port | Published to host |
|---|---|---|
| NGINX | 443 | Yes, port 443 |
| WordPress / PHP-FPM | 9000, if configured as such | No |
| MariaDB | 3306 | No |

### Inspect the network

List Docker networks:
```
docker network ls
```

Inspect the project's actual network:
```
docker network inspect <network_name>
```

Replace `<network_name>` with the name shown by Docker.

The network name may include a Compose project prefix, depending on how the project was started.

## 9. Persistent Data

The project stores persistent data on the host, outside the container writable layers.

The configured host directory is:

```text
/home/aunoguei/data/
├── mariadb/
└── wordpress/
```

The actual paths must match the volume configuration in `srcs/docker-compose.yml`.

### MariaDB storage

MariaDB stores its database files inside the container at:

```text
/var/lib/mysql
```

The Compose configuration maps this directory to the host-backed `mariadb` volume.

A local-driver volume can be configured with bind options:

```yaml
volumes:
  mariadb:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/aunoguei/data/mariadb
```

This configuration creates a Docker-managed volume object that references a host directory. It does not mean the database is stored only in Docker's default volume directory.

### WordPress storage

The WordPress volume uses the same general approach with the host directory:

```text
/home/aunoguei/data/wordpress
```

Check the Compose configuration to confirm the container destination. The destination depends on how the WordPress files are arranged in the image.

### Prepare the directories

The Makefile's `prepare` target creates both host directories:

```bash
make prepare
```

Equivalent commands are:

```bash
mkdir -p /home/aunoguei/data/mariadb
mkdir -p /home/aunoguei/data/wordpress
```

The `prepare` target creates directories but does not explicitly assign the ownership required by every container process.

### MariaDB ownership and permissions

MariaDB must be able to read and write its data directory as the Linux `mysql` account.

Inspect the directory's numeric ownership and permissions:

```bash
ls -ldn /home/aunoguei/data/mariadb
```

In the current Debian-based MariaDB image, the `mysql` account is expected to use UID `100` and GID `101`. Verify these values against the actual image rather than assuming they will remain unchanged.

For example, to inspect the account inside a running container:

```bash
docker compose -f srcs/docker-compose.yml exec mariadb id mysql
```

Correct ownership only when required, using the UID and GID verified for the image.

Do not recursively change ownership on every startup without a specific reason.

### Persistence rules

Keep the following distinctions in mind:

- Removing a container does not automatically delete data stored in a separate host directory.
- `docker compose down` normally removes the project's containers and network without deleting named volumes.
- `docker compose down -v` can remove Compose-managed volumes and should not be used casually.
- Removing a Docker volume object does not necessarily delete the external host directory used by a bind-backed volume.
- Deleting the host data directory can permanently destroy the corresponding data.

Always back up important database data before performing destructive maintenance.

## 10. Build, Run and Stop

The Makefile checks the required secrets and environment variables, prepares storage, and builds and starts the services.

```bash
make
```

Equivalent explicit target:

```bash
make up
```

Other targets:

| Command | Action |
|---|---|
| `make check-env` | Check required environment variables |
| `make check-secrets` | Check required secret files |
| `make prepare` | Create host data directories |
| `make logs` | Display service logs |
| `make down` | Stop and remove Compose containers and network |
| `make re` | Run `down` followed by `up` |
| `make clean` | Run `down`; does not delete host data |

To rebuild and recreate a single service after changing its Dockerfile or build-time files, for example MariaDB:

```bash
docker compose -f srcs/docker-compose.yml build mariadb
docker compose -f srcs/docker-compose.yml up -d --force-recreate mariadb
```

A rebuild normally does not require deleting persistent data. The `re` target does not force every image to be rebuilt from scratch.

## 11. Development and Debugging

### Service status and logs

```bash
docker compose -f srcs/docker-compose.yml ps
docker compose -f srcs/docker-compose.yml ps -a
docker compose -f srcs/docker-compose.yml logs --tail=100 nginx wordpress mariadb
docker compose -f srcs/docker-compose.yml logs -f mariadb
```

Press `Ctrl+C` to stop following logs; this does not stop the container.

### Open a shell in a running service

```bash
docker compose -f srcs/docker-compose.yml exec nginx sh
docker compose -f srcs/docker-compose.yml exec wordpress sh
docker compose -f srcs/docker-compose.yml exec mariadb sh
```

### Validate NGINX

```bash
docker compose -f srcs/docker-compose.yml exec nginx nginx -t
```

This requires the NGINX container to be running. If NGINX fails to start or PHP requests return gateway errors, check the NGINX configuration, TLS certificate and key paths, PHP-FPM status, the `fastcgi_pass` destination, and network connectivity.

### Inspect Docker resources

```bash
docker ps -a
docker network ls
docker network inspect <network_name>
docker volume ls
docker volume inspect <volume_name>
```

Use the actual network and volume names reported by Docker; Compose may add a project-name prefix. For bind-backed volumes, verify the configured host path in the volume options and in `srcs/docker-compose.yml`.

## 12. Database Verification

The following examples use the mounted root secret and assume the service is named `mariadb`.

List databases:

```bash
docker compose -f srcs/docker-compose.yml exec mariadb sh -c \
'mariadb -u root -p"$(cat /run/secrets/db_root_password)" -e "SHOW DATABASES;"'
```

List database accounts:

```bash
docker compose -f srcs/docker-compose.yml exec mariadb sh -c \
'mariadb -u root -p"$(cat /run/secrets/db_root_password)" -e "SELECT User, Host FROM mysql.user;"'
```

Inspect tables in the application database, replacing `wordpress` with the actual value of `MYSQL_DATABASE`:

```bash
docker compose -f srcs/docker-compose.yml exec mariadb sh -c \
'mariadb -u root -p"$(cat /run/secrets/db_root_password)" -e "USE wordpress; SHOW TABLES;"'
```

An empty table list can be normal before WordPress has completed its installation.

## 13. MariaDB Initialization

The MariaDB entrypoint is installed at `/usr/local/bin/init-mariadb.sh`. It checks whether `/var/lib/mysql/mysql` exists to determine whether the data directory has already been initialized.

For a new data directory, the script initializes the system tables, reads the mounted password secrets, starts a temporary local server for initial SQL configuration, stops that server, and starts the normal MariaDB process:

```bash
exec gosu mysql mariadbd
```

`gosu` switches to the dedicated `mysql` user, and `exec` replaces the shell with the database process. MariaDB must remain in the foreground for the container to keep running.

Existing database files are reused on subsequent starts. Changing `.env` or a secret file does not automatically update credentials already stored in an initialized database.

## 14. Troubleshooting and Safe Cleanup

**A container exits or restarts**

```bash
docker compose -f srcs/docker-compose.yml ps -a
docker compose -f srcs/docker-compose.yml logs --tail=100 <service>
```

Check missing configuration or secrets, invalid paths, permission errors, and service startup failures.

**WordPress cannot connect to MariaDB**

Verify that MariaDB is running, the database name and account are correct, and WordPress uses host `mariadb` rather than `localhost` or a fixed container IP. Remember that changing a secret file does not change an existing database account password.

**NGINX cannot reach PHP-FPM**

Check that both containers are running and share the Compose network, and that `fastcgi_pass` matches the actual PHP-FPM service name and listening port.

**MariaDB reports permission errors**

Inspect the host data directory's ownership and compare it with the `mysql` UID/GID inside the container. Change ownership only when needed and after verifying the correct IDs.

**Keep persistent data safe**

`make down` and `make clean` remove the Compose containers and network; they do not intentionally delete the host data directories. Do not delete `/home/aunoguei/data/mariadb` or `/home/aunoguei/data/wordpress` as a routine restart or troubleshooting step.

Avoid broad cleanup commands such as:

```bash
docker system prune -a --volumes
```

They can remove resources used by other projects. Back up important data before any destructive maintenance.



