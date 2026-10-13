# User Documentation

## 1. Overview

This project provides a WordPress website running in a Docker-based infrastructure. It includes three services:

- **NGINX**: Handles secure HTTPS connections.
- **WordPress**: Provides the website and its administration interface.
- **MariaDB**: Stores WordPress data.

## 2. Requirements

Before starting the project, ensure Docker, Docker Compose, and GNU Make are installed.

The following files must also be configured:

- `srcs/.env`: Contains the domain name, database settings, and WordPress usernames and email addresses.
- `secrets/`: Contains the four required password files:
  - `db_root_password.txt`
  - `db_password.txt`
  - `wp_admin_password.txt`
  - `wp_user_password.txt`

Keep these files private and never commit them to the repository.

## 3. Starting the Website

From the project root, run:

```bash
make
```

This command checks the configuration and secret files, creates the data directories, builds the images, and starts the services.

To stop the services, run:
```
make down
```

To rebuild and restart the services, run:
```
make re
```

To view the service logs, run:
```
make logs
```

## 4. Accessing WordPress

Once the services are running, open the following address in your browser:
```
https://<DOMAIN_NAME>
```

Replace `<DOMAIN_NAME>` with the value configured in `srcs/.env`.

If the domain does not resolve, ensure it points to the IP address of your virtual machine by configuring your local `/etc/hosts` file if necessary.

To access the WordPress administration dashboard, visit:
```
https://<DOMAIN_NAME>/wp-admin/
```

Log in using the administrator credentials configured for the project.

## 5. Credentials

The project uses separate credentials for the database, WordPress administrator, and WordPress user.

Passwords are stored in the files under `secrets/` and provided to the containers through Docker secrets.

Keep passwords secure and do not share or commit them. To change credentials, update the relevant configuration and secret files as appropriate; changing a secret file alone may not update an already initialized database or WordPress installation.

## 6. Data Persistence

Website files and database data are stored on the host:
- WordPress: `/home/aunoguei/data/wordpress`
- MariaDB: `/home/aunoguei/data/mariadb`

Stopping the services with `make down` does not delete these directories, so data persists across container restarts.

Back up these directories regularly to protect your website and database.

## 7. Troubleshooting

If the website is unavailable:

1. Check that Docker is running.
2. Run `make logs` to inspect service logs.
3. Verify the values in `srcs/.env` and ensure all required secret files exist and are non-empty.
4. Check that the domain resolves to the virtual machine's IP address.
5. Confirm that port `443` is accessible.

For implementation details and further troubleshooting, see [DEV_DOC.md](DEV_DOC.md).