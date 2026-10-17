DATA_DIR = /home/aunoguei/data
SECRETS_DIR = secrets
COMPOSE_FILE = srcs/docker-compose.yml
ENV_FILE = srcs/.env

all: up

check-secrets:
	@test -s $(SECRETS_DIR)/db_root_password.txt || \
		(echo "Error: db_root_password.txt is missing or empty" >&2; exit 1)
	@test -s $(SECRETS_DIR)/db_password.txt || \
		(echo "Error: db_password.txt is missing or empty" >&2; exit 1)
	@test -s $(SECRETS_DIR)/wp_admin_password.txt || \
		(echo "Error: wp_admin_password.txt is missing or empty" >&2; exit 1)
	@test -s $(SECRETS_DIR)/wp_user_password.txt || \
		(echo "Error: wp_user_password.txt is missing or empty" >&2; exit 1)
	@test -s $(SECRETS_DIR)/ftp_password.txt || \
		(echo "Error: ftp_password.txt is missing or empty" >&2; exit 1)

check-env:
	@test -s $(ENV_FILE) || \
		(echo "Error: srcs/.env is missing or empty" >&2; exit 1)
	@grep -q '^DOMAIN_NAME=.' $(ENV_FILE) || \
		(echo "Error: DOMAIN_NAME is missing or empty" >&2; exit 1)
	@grep -q '^MYSQL_DATABASE=.' $(ENV_FILE) || \
		(echo "Error: MYSQL_DATABASE is missing or empty" >&2; exit 1)
	@grep -q '^MYSQL_USER=.' $(ENV_FILE) || \
		(echo "Error: MYSQL_USER is missing or empty" >&2; exit 1)
	@grep -q '^WP_ADMIN_USER=.' $(ENV_FILE) || \
		(echo "Error: WP_ADMIN_USER is missing or empty" >&2; exit 1)
	@grep -q '^WP_ADMIN_EMAIL=.' $(ENV_FILE) || \
		(echo "Error: WP_ADMIN_EMAIL is missing or empty" >&2; exit 1)
	@grep -q '^WP_USER=.' $(ENV_FILE) || \
		(echo "Error: WP_USER is missing or empty" >&2; exit 1)
	@grep -q '^WP_USER_EMAIL=.' $(ENV_FILE) || \
		(echo "Error: WP_USER_EMAIL is missing or empty" >&2; exit 1)
	@grep -q '^FTP_USER=.' $(ENV_FILE) || \
		(echo "Error: FTP_USER is missing or empty" >&2; exit 1)
	@grep -q '^FTP_PASV_ADDRESS=.' $(ENV_FILE) || \
		(echo "Error: FTP_PASV_ADDRESS is missing or empty" >&2; exit 1)
	@grep -q '^FTP_PASV_MIN_PORT=.' $(ENV_FILE) || \
		(echo "Error: FTP_PASV_MIN_PORT is missing or empty" >&2; exit 1)
	@grep -q '^FTP_PASV_MAX_PORT=.' $(ENV_FILE) || \
		(echo "Error: FTP_PASV_MAX_PORT is missing or empty" >&2; exit 1)

prepare:
	mkdir -p $(DATA_DIR)/mariadb
	mkdir -p $(DATA_DIR)/wordpress

up: check-secrets check-env prepare
	docker compose -f $(COMPOSE_FILE) up -d --build

down:
	docker compose -f $(COMPOSE_FILE) down

logs:
	docker compose -f $(COMPOSE_FILE) logs

re: down up

clean: down

fclean:
	docker compose -f $(COMPOSE_FILE) down --volumes --rmi local
	sudo find $(DATA_DIR)/mariadb -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +
	sudo find $(DATA_DIR)/wordpress -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +

.PHONY: all check-secrets check-env prepare up down clean logs re
