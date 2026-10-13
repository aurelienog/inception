*This project has been created as part of the 42 curriculum by aunoguei.*

# Inception

## Table of Contents

- [Description](#description)
- [Instructions](#instructions)
- [Project Description](#project-description)
- [Main Design Choices](#main-design-choices)
- [Virtual Machines vs Docker](#virtual-machines-vs-docker)
- [Secrets vs Environment Variables](#secrets-vs-environment-variables)
- [Docker Network vs Host Network](#docker-network-vs-host-network)
- [Docker Volumes vs Bind Mounts](#docker-volumes-vs-bind-mounts)
- [Resources](#resources)
- [AI Usage](#ai-usage)

## Description

Inception is a system administration project from the 42 curriculum
focused on containerization, service isolation and infrastructure
management using Docker.

The goal is to build a small, multi-service web infrastructure using
custom Docker images and Docker Compose. Each service has a specific
responsibility, and the services communicate through a dedicated
network.

The project explores several fundamental concepts:

- Containerization and custom image creation.
- Service isolation and network communication.
- HTTPS configuration and secure web access.
- Database initialization and application configuration.
- Persistent storage and data management.
- Credential management using Docker secrets.
- Infrastructure deployment and lifecycle management.

The infrastructure consists of NGINX, WordPress and MariaDB, running
as separate services within a Docker-based environment.

## Instructions

### Prerequisites

The project requires the following environment:
- A Linux virtual machine.
- Docker Engine.
- Docker Compose.
- GNU Make.
- Internet access to download required packages and build
dependencies.

Docker must be installed and running, and the user must have permission
to execute Docker commands.

### Configuration

Before starting the infrastructure, prepare the configuration and
credential files expected by the project.

The repository uses:

- `srcs/.env` for non-sensitive configuration.
- `secrets/` for the password files required by the services.

The Makefile checks that the environment file contains all required
variables and that the four password files exist and are not empty.

Sensitive files must not be committed to version control.

For the complete list of variables, secret files, permissions and
configuration requirements, see
[`DEV_DOC.md`](DEV_DOC.md).

### Build and launch

From the repository root, run:

```bash
make
```

The default target invokes `make up`, which performs the following
operations:
1. Checks that the required secret files exist and are not empty.
2. Checks that srcs/.env contains the required configuration variables.
3. Creates the persistent data directories for MariaDB and WordPress.
4. Builds the required images and starts the services in detached mode
   using Docker Compose.

The persistent data directories are created under:
```
/home/aunoguei/data/
├── mariadb/
└── wordpress/
```

The Compose configuration is located at
`srcs/docker-compose.yml`.

### Stop the Infrastructure

To stop the services, run:
```bash
make down
```

Stopping the stack removes the Compose containers and network, but does not delete the persistent database files.

### Additional Makefile Targets

The Makefile provides the following targets:

| Command | Description |
|---|---|
| `make` | Runs the default target and starts the infrastructure. |
| `make up` | Validates the configuration, prepares storage, builds the images and starts the services. |
| `make down` | Stops and removes the Compose containers and network. |
| `make logs` | Displays the logs of the Compose services. |
| `make re` | Stops the infrastructure and starts it again. |
| `make clean` | Stops the infrastructure, equivalent to `make down`. |

The `make down` and `make clean` targets do not explicitly remove
persistent volumes or delete the host data directories.

For end-user instructions, including website access and service checks,
see [`USER_DOC.md`](USER_DOC.md).

For detailed environment setup, configuration, container management
and persistent storage information, see [`DEV_DOC.md`](DEV_DOC.md).

## Project Description

### Architecture

The project follows a three-tier architecture in which the web server,
application and database are separated into independent services.

```text
                 Browser
                    |
                 HTTPS :443
                    |
                    v
              +-----------+
              |   NGINX   |
              |TLS 1.2/1.3|
              +-----+-----+
                    |
                 FastCGI
                    |
                    v
              +-----------+
              | WordPress |
              |  PHP-FPM  |
              +-----+-----+
                    |
                 SQL :3306
                    |
                    v
              +-----------+
              |  MariaDB  |
              +-----------+

           Dedicated Docker network

Persistent host data:
  /home/aunoguei/data/
  ├── mariadb/
  └── wordpress/
```

#### NGINX

NGINX is the public entry point of the infrastructure. It handles
HTTPS connections and forwards PHP requests to WordPress through
FastCGI.
TLS 1.2 and TLS 1.3 are configured for encrypted communication
between the browser and the web server.

#### WordPress
WordPress provides the website and its content management
functionality. It runs with PHP-FPM and communicates with MariaDB
to store and retrieve application data.

#### MariaDB
MariaDB provides the relational database used by WordPress. Its
initialization procedure prepares the database and application
account before the database server runs normally.  

The services communicate through the **internal Docker network**.
**Only NGINX exposes the public HTTPS port**; WordPress and MariaDB
communicate internally without requiring their service ports to be
published on the host.
Persistent storage keeps the application files and database data
outside the lifecycle of individual containers.

### Project structure

The repository contains the files required to build, configure and
manage the infrastructure, together with its documentation.

```text
inception/
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
├── .gitignore
├── secrets/
└── srcs/
    ├── .env
    ├── docker-compose.yml
    └── requirements/
        ├── nginx/
        ├── wordpress/
        └── mariadb/
```

The main components are:
- **Makefile**: provides convenient commands for building,
  starting and stopping the infrastructure.
- **docker-compose.yml**: defines the services, their build
  configurations, networking, storage and runtime settings.
- **requirements/nginx/**: contains the NGINX image definition
  and web server configuration.
- **requirements/wordpress/**: contains the WordPress image
  definition and application setup.
- **requirements/mariadb/**: contains the MariaDB image
  definition and database initialization script.
- **.env**: contains non-sensitive configuration variables.
- **secrets/**: contains local files used to supply sensitive
  credentials to the services.

The source files define how the individual services are built
and configured. Docker Compose brings them together into a
single infrastructure.

The .env file contains non-sensitive configuration, while database passwords are supplied through secret files. Sensitive configuration files must be excluded from version control.

The root-level documentation is divided by purpose:

- **README.md** introduces the project and explains its architecture
  and technical choices.
- **USER_DOC.md** explains how to operate the infrastructure.
- **DEV_DOC.md** documents environment setup, configuration,
  development and container management.

### Docker and Its Role in the Project

Docker allows applications and their dependencies to be packaged
into images and executed as isolated containers.

Unlike a traditional installation in which multiple applications
share the host filesystem and runtime environment, this project
separates the web server, application and database into distinct
services.

Each service has its own build context and Dockerfile. This makes
its dependencies, installation procedure and configuration explicit.

**Docker Compose** describes how the services work together, including:
- Service definitions and build contexts.
- Container networking.
- Persistent storage.
- Environment variables and secrets.
- Port publishing and restart policies.

This approach makes the infrastructure easier to reproduce,
maintain and troubleshoot.

The project uses custom images rather than relying exclusively on
preconfigured application images. This provides greater control
over the software installed and the startup procedures.

The infrastructure is designed around the following principles:
- **Separation of concerns**: each service has one primary role.
- **Isolation**: services run in separate containers.
- **Reproducibility**: Dockerfiles describe the build process.
- **Controlled communication**: services use a dedicated network.
- **Persistence**: application data survives container recreation.
- **Credential separation**: passwords are supplied separately
  from ordinary application configuration.
- **Maintainability**: Docker Compose and the Makefile provide
  a consistent way to manage the infrastructure.


## Main Design Choices

### Custom images

Each service has its own Dockerfile and build context. This makes
the installation and configuration process explicit and allows
each service to be maintained independently.

Image tags use explicit versions rather than `latest`.

### Service isolation

NGINX, WordPress and MariaDB run in separate containers.
This separation reduces unnecessary dependencies between services
and makes their responsibilities easier to understand.

### Internal networking

A dedicated **Docker bridge** network allows the services to
communicate using their Compose service names.

Only the web server needs a published port for external access.
The application and database remain on the internal service
network.

### Persistent storage

Application files and database data are stored under
```/home/aunoguei/data/``` on the host.

The Compose configuration uses **named volumes** with the local
driver and bind-related options to map the required host
directories to the appropriate container paths.

This keeps the database files in the required host directory while using a Docker-managed named volume in Compose.

Data persist independently of container
recreation.

### Credential management

Non-sensitive configuration is supplied through environment
variables, while passwords are provided through Docker secret
files.
This separates ordinary application settings from sensitive
credentials. Local secret files still require appropriate host
permissions and must not be committed to version control.

### Database initialization
The MariaDB service includes an initialization script that
prepares the database on first startup and then launches the
database server.
Keeping this procedure in the service configuration makes
database setup reproducible.

### Restart policy

The services uses `restart: always`, so Docker attempts to restart it when its process exits.

## Virtual Machines vs Docker

Virtual machines and Docker containers provide different levels
of isolation and serve different purposes.

| Aspect | Virtual Machines | Docker Containers |
|---|---|---|
| Operating system | Each VM runs its own guest operating system and kernel. | Containers share the host kernel. |
| Resource usage | Generally requires more memory and storage because each VM includes a guest OS. | Generally has lower overhead for application workloads. |
| Isolation | Provides a separate guest OS environment. | Provides process, filesystem and network isolation while sharing the host kernel. |
| Portability | VM images package an operating system and its environment. | Images package an application and its dependencies. |
| Typical use cases | Running different operating systems or creating isolated machine environments. | Packaging applications, running services and reproducing deployment environments. |

A virtual machine is useful when a separate operating system
or kernel environment is required. Docker is particularly useful
when applications need to be packaged, deployed and managed
as independent services.
In this project, both technologies are used for different
purposes. The project runs inside a Linux virtual machine,
while Docker manages the NGINX, WordPress and MariaDB services
within that environment.
The VM provides the host environment, and Docker provides
application-level isolation and service management.

## Secrets vs Environment Variables

Environment variables and Docker secrets are both mechanisms
for supplying configuration to services, but they have
different purposes.

| Aspect | Environment Variables | Docker Secrets |
|---|---|---|
| Main purpose | General application configuration. | Sensitive values such as passwords and credentials. |
| Access | Available to processes through their environment. | Provided to authorized services as files. |
| Configuration | Convenient for values such as domain names and database names. | Suitable for credentials that should be separated from ordinary configuration. |
| Main consideration | Sensitive values can be exposed through process inspection, diagnostics or configuration handling. | File-based delivery reduces some exposure risks but does not automatically guarantee encrypted storage in every deployment mode. |

Environment variables are convenient for non-sensitive values
such as domain names, database names and service settings.
Passwords should not be embedded in Dockerfiles, committed to
version control or unnecessarily exposed in process environments
and logs.
Docker secrets allow a service to access a sensitive value through
a file, typically under /run/secrets/. This avoids having to
pass the password as an ordinary environment variable.
However, secret handling depends on the deployment environment.
Docker Swarm provides managed secrets with specific security
properties, whereas local Docker Compose secrets commonly use
host-side files as their source.
In this project, local secret files are used to provide passwords
to the services. Their security therefore also depends on host
permissions and the protection of the files themselves.
The main design principle is to use environment variables for
ordinary configuration and secret files for sensitive credentials.

## Docker Network vs Host Network

Docker provides different networking modes depending on the
required communication and isolation.

### Dedicated bridge network

A bridge network connects containers while keeping
their communication separate from unrelated containers.

```
                 Docker Host
                      |
                    Docker
                      |
                Bridge Network
                      |
          +-----------+-----------+
          |           |           |
        NGINX      WordPress    MariaDB
```
A dedicated bridge network offers several advantages:
- Containers can communicate through Docker networking.
- Compose services can resolve one another by service name.
- Internal service ports do not need to be published on the host.
- Network membership helps separate the application from
  unrelated containers.

This project uses a dedicated Docker network for communication between NGINX, WordPress and MariaDB.
Compose services can use service names instead of fixed IP addresses.

### Host network

With host networking, a container shares the host's network
namespace rather than using an independent container network
namespace.
```
             Docker Host
                  |
             Host Network
                  |
               Container
```

Host networking can be useful when an application requires
direct access to the host network stack or when its networking
requirements make this arrangement appropriate.

However, it reduces network isolation and changes how ports
are exposed and managed. Port publishing is generally not
needed in host networking mode.

For this project, a dedicated bridge network is more appropriate
because the services require controlled internal communication
and only NGINX needs to expose a public service port.

## Docker Volumes vs Bind Mounts

Containers are designed to be replaceable. Data stored only in
a container's writable layer is not a reliable way to preserve
application state across container replacement.

Docker volumes and bind mounts provide ways to store data
outside that layer.

| Aspect | Named Volumes | Bind Mounts |
|---|---|---|
| Storage location | Managed through Docker's volume system. | A specific path on the host filesystem. |
| Configuration | Referenced by volume name. | Requires a host path. |
| Management | Docker manages the volume lifecycle. | The host filesystem and its permissions must be managed carefully. |
| Common use | Persistent application data. | Sharing specific host directories with containers. |

A named volume can be declared and mounted as follows:

```
services:
  example:
    volumes:
      - application_data:/var/lib/example

volumes:
  application_data:
```

A bind mount directly maps a host directory into a container:
```
services:
  example:
    volumes:
      - /path/on/host:/var/lib/example
```

**Named volumes are convenient because Docker manages them
through its volume system**. 

Bind mounts are useful when a
specific host directory must be used or accessed directly.
They provide explicit control over the host location but require careful handling of permissions and path existence.

### Storage in This Project

This project uses named volumes with the local driver and
bind-related options to keep persistent data in the required
host directories:
```
/home/aunoguei/data/
├── mariadb/
└── wordpress/
```

The MariaDB data directory inside the container is
```/var/lib/mysql```.

The volume configuration maps persistent storage to the
specified host paths, allowing the database and WordPress
files to survive container recreation.
Although the Compose configuration references named volumes,
the local driver's bind options mean that the underlying
storage uses specific host directories.
This distinction matters when inspecting where the data is
stored or planning backups and permissions.

## Resources

### Docker and Docker Compose

- [Docker documentation](https://docs.docker.com/)
- [Docker images](https://docs.docker.com/get-started/docker-concepts/the-basics/what-is-an-image/)
- [Docker containers](https://docs.docker.com/get-started/docker-concepts/the-basics/what-is-a-container/)
- [Docker Compose](https://docs.docker.com/compose/)
- [Compose file reference](https://docs.docker.com/reference/compose-file/)
- [Docker networking](https://docs.docker.com/engine/network/)
- [Docker volumes](https://docs.docker.com/engine/storage/volumes/)
- [Compose environment variables](https://docs.docker.com/compose/how-tos/environment-variables/)
- [Guide](https://liora.io/docker-guide-complet)
- [Registry](https://docs.docker.com/get-started/docker-concepts/the-basics/what-is-a-registry/)
- [Networking in Compose](https://docs.docker.com/compose/how-tos/networking)
[Control in Compose](https://docs.docker.com/compose/how-tos/startup-order/)
- [Bridge](https://docs.docker.com/engine/network/drivers/bridge/)
- [Container & Ip](https://www.freecodecamp.org/espanol/news/como-obtener-la-direccion-ip-de-un-contenedor-docker-explicado-con-ejemplos/)
- [Secrets](https://docs.docker.com/engine/swarm/secrets/)
- [Docker tips](https://www.youtube.com/watch?v=EzUDAQGNUk8)

### MariaDB and SQL

- [MariaDB documentation](https://mariadb.com/docs/)
- [MariaDB account management](https://mariadb.com/docs/server/reference/sql-statements/account-management-sql-statements)
- [MariaDB GRANT statement](https://mariadb.com/docs/server/reference/sql-statements/account-management-sql-statements/grant)
- [SQLBolt interactive SQL lessons](https://sqlbolt.com/)
- [SQL - Guide](https://liora.io/sql-tout-savoir)

### Linux and System Administration

- [Files System](https://medium.com/aws-devops-simplified/understanding-the-linux-file-system-a-detailed-guide-d11784447747)
- [Daemons TCP/IP](https://www.ibm.com/docs/es/aix/7.2.0?topic=protocol-tcpip-daemons)
- [Linux Processes](https://www.geeksforgeeks.org/linux-unix/processes-in-linuxunix/)
- [Processes](https://medium.com/@nakuldesai123/understanding-the-linux-processes-basic-e6900de2454b)
- [PID1](https://www.devopsschool.com/blog/understanding-pid-1-physical-servers-virtual-machines-and-containers/)
- [PID1 - secure](https://dev.to/alanwest/why-your-docker-containers-refuse-to-die-the-pid-1-problem-e70)
- [Signals](https://dev.to/axisinfo_0a61830e06c3c950/understanding-process-signals-in-linux-5gb)
- [Linux control groups](https://medium.com/@dmosyan/linux-cgroups-explained-how-containers-use-it-c99eebb8c9c6)
- [Linux Namespaces](https://medium.com/@teddyking/linux-namespaces-850489d3ccf)
- [Unix Sockets](https://www.geeksforgeeks.org/linux-unix/understanding-unix-sockets/)
- [debian - versions](https://cdimage.debian.org/cdimage/archive/)

### NGINX and PHP-FPM

- [NGINX documentation](https://nginx.org/en/docs/)
- [NGINX beginner's guide](https://nginx.org/en/docs/beginners_guide.html)
- [PHP-FPM documentation](https://www.php.net/install.fpm)
- [NGINX](https://nginx.org/index.html)
- [NGINX SolarWinds Guides](https://www.papertrail.com/solution/guides/nginx/)
- [NGINX SSL Termination](https://docs.nginx.com/nginx/admin-guide/security-controls/terminating-ssl-http/)
- [fastcgi_pass](https://nginx.org/en/docs/http/ngx_http_fastcgi_module.html)

### WordPress

- [WordPress administration documentation](https://developer.wordpress.org/advanced-administration/)
- [WordPress Config](https://developer.wordpress.org/advanced-administration/wordpress/wp-config/)

### AI Usage

AI tools were used as learning and development support during
this project rather than as a substitute for understanding, testing or validating the implementation.

Their assistance included:
- Technical learning: clarifying Docker concepts such as
  images, containers, networking, volumes and secrets.
- Linux and process management: understanding process
  execution, Unix sockets, user privileges and the role of the
  main process in a container.
- Database initialization: reviewing the MariaDB startup
  procedure and understanding the purpose of its initialization
  script.
- Troubleshooting: helping investigate container startup,
  database connectivity and persistent storage configuration.
- Documentation: organizing the project documentation,
  improving technical explanations and reviewing Markdown
  structure.

AI-generated explanations and suggestions were treated as
learning aids rather than as authoritative sources. Relevant
information was checked against the official documentation,
the project configuration and observed command output.
The implementation was tested through image builds, container
startup checks, database verification and inspection of the
persistent storage configuration.

#





To start MariaDB directly with Docker Compose:

```bash
docker compose -f srcs/docker-compose.yml up -d --build mariadb
```

### Check the service

```bash
docker compose -f srcs/docker-compose.yml ps
docker compose -f srcs/docker-compose.yml logs mariadb
```

The log message `ready for connections` indicates that the database server has started successfully.

To list the databases without displaying the password:

```bash
docker exec mariadb sh -c \
'mariadb -u root -p"$(cat /run/secrets/db_root_password)" -e "SHOW DATABASES;"'
```

1. Environment configuration

Create ```srcs/.env``` with the required non-sensitive configuration variables:

- DOMAIN_NAME
- MYSQL_DATABASE
- MYSQL_USER
- WP_ADMIN_USER
- WP_ADMIN_EMAIL
- WP_USER
- WP_USER_EMAIL

The Makefile checks that these variables exist and are not empty. Additional variables may be required by the Compose configuration or service initialization scripts.

2. Secret files

Create the following files inside the root-level secrets/ directory:

secrets/
├── db_root_password.txt
├── db_password.txt
├── wp_admin_password.txt
└── wp_user_password.txt
Each file must contain the corresponding password and must not be empty.

Keep these files out of version control. Do not commit real credentials or copy passwords into Dockerfiles or the README.

For detailed configuration requirements and secret handling, see ```DEV_DOC.md```.

### MariaDB

```
              Container
            ┌─────────────┐
            │   MariaDB   │
            │             │
            │ /var/lib/   │
            │    mysql    │
            └──────┬──────┘
                   │
                   ▼
             Docker volume
                   │
                   ▼
           /home/aunoguei/data/
                  mariadb
```

```
WordPress
    │
    │ consultas SQL
    ▼
 mariadbd
    │
    ▼
 datos
```

DROP PRIVILEGES :
```
                    DOCKER
                       │
                       │ docker run
                       ▼
              ┌─────────────────┐
              │       PID 1     │
              │ init-mariadb.sh │
              │                 │
              │     usuario     │
              │       root      │
              └────────┬────────┘
                       │
                       │ prepara
                       │
                       ├── /var/lib/mysql
                       ├── permisos
                       ├── configuración
                       └── inicialización
                       │
                       │ cambia privilegios
                       ▼
              ┌─────────────────┐
              │     mariadbd    │
              │                 │
              │ usuario: mysql  │
              │      PID 1      │
              └────────┬────────┘
                       │
                       ▼
                 MariaDB server
```
mariadbd → el servidor MariaDB (d = daemon)
mysql → usuario Linux con pocos privilegios que ejecuta el servidor
exec → reemplaza el proceso de inicialización por el proceso real, permitiendo que mariadbd sea el proceso principal del contenedor.

socket necessary:
```
mariadb (cliente)
      │
      │ Unix socket
      ▼
/run/mysqld/mysqld.sock
      │
      ▼
mariadbd (servidor)

---

root
 │
 ├── mkdir /run/mysqld
 │
 └── chown mysql:mysql /run/mysqld
             │
             ▼
           mysql
             │
             └── mariadbd
```
la imagen mariadb:test ya contiene una base de datos inicializada por el paquete de Debian.
Por ejemplo:
- ibdata1 e ib_logfile0: archivos relacionados con el almacenamiento y la recuperación de InnoDB.
- mysql/: contiene las tablas internas del sistema, incluidas las relacionadas con usuarios y permisos.
- performance_schema/ y sys/: bases de datos del sistema.


Un socket Unix permite que dos procesos del mismo sistema se comuniquen sin utilizar una conexión TCP. Más adelante lo usamos para conectarnos al servidor temporal.


¿Por qué arranca un servidor temporal? MariaDB necesita estar funcionando para poder ejecutar las instrucciones SQL que crean la base de datos y los usuarios. El servidor temporal se utiliza para configurar el sistema antes de iniciar el servidor definitivo.

 explain the use of Docker and the sources
included in the project. It must indicate the main design choices, as well as a
comparison between:

### Virtual Machines vs Docker

VM : useful if total isolation needed or if different OS needs to be running on a same server?

Docker: pipeline CI/CD, micro-services, deploy...

### Secrets vs Environment Variables

The first issue with using environment variables is that they can be viewed in the process list. root user, you would see all processes that are currently running and would have access to every secret.

Second issue: Docker stores each layer in the file system and also pushes these layers to the registry that you are using. Everybody with access to the registry can get access to the secrets.

The RUN command now includes the mount parameter with the secret type definition. This is the way to go for managing build secrets in Docker. 

Secrets are encrypted and only accessible to the containers that need them.
Inside the container, the secret appears as a file, not a env variable. to avoid leaking secrets in logs or process lists.

### Docker Network vs Host Network

**Docker network**
Los containers se comunican dentro de la red Docker.
```
Host
│
Docker
│
└── custom bridge network
       ├── nginx
       ├── wordpress
       └── mariadb
```

**Host network**
El container comparte directamente la red del host
```
Container
     │
     ▼
Host network stack
```


bridge: default network, container get an internal IP and talk througt that

host: the container shares the host netowrk stack, no isolation, remove port mapping. Danger

overlay: multi-host communication like docker swarm, for clustering

Custom networks:
    - gives containers predictable DNS names
    - isolate a group of containers
```
docker network create <network name>
docker run -d --name <container name> --network <network name> nginx
```
-> no Ips needed, any container can reach web by using its name

para connectar networks (ejemplo: shared DB):
```
docker network connect <network1 name> <network2 name>
```
pero rompe un poco la isolation


### Docker Volumes vs Bind Mounts

Named volume: managed by docker -> production

bind mounts: map a specific directory on your host to a directory inside the container -> local development . Docker does not manage directly that volume

Bind mount: ./something:/var/lib/mysql
Named volume: mariadb:/var/lib/mysql
```












## MariaDB Service

The MariaDB image is built from `debian:12`, rather than using a prebuilt MariaDB application image.

The Dockerfile installs:

- `mariadb-server`
- `gosu`, used to start the database server under the dedicated Linux `mysql` account

The initialization script, `init-mariadb.sh`, performs the following operations:

1. Creates the runtime directory `/run/mysqld` and assigns it to the `mysql` user.
2. Checks whether the MariaDB data directory has already been initialized.
3. Initializes the data directory on first startup.
4. Reads the root and application database passwords from Docker secret files.
5. Starts a temporary local MariaDB server to perform the initial SQL configuration.
6. Creates the application database and user, grants the required database privileges, and configures the root password.
7. Stops the temporary server.
8. Starts the normal MariaDB server using `exec gosu mysql mariadbd`.

The temporary server uses a Unix socket and disables TCP networking during initialization. This allows the initialization SQL to run before the normal database server starts.

The final `exec` replaces the shell process with MariaDB. This allows the database server to become the container's main process and receive container lifecycle signals directly.

Initialization is conditional: an existing initialized data directory is reused instead of being initialized again.

The database is not published on a host port. Other services on the Compose network will be able to connect to the MariaDB service using its service name and TCP port `3306`.

```
                    Internet / Browser
                           │
                        HTTPS :443
                           │
                           ▼
                  ┌─────────────────┐
                  │     NGINX       │
                  │ TLS termination │
                  └────────┬────────┘
                           │ FastCGI
                           │ :9000
                           ▼
                  ┌─────────────────┐
                  │ WordPress/PHP   │
                  │     PHP-FPM     │
                  └────────┬────────┘
                           │ MySQL protocol
                           │ :3306
                           ▼
                  ┌─────────────────┐
                  │    MariaDB      │
                  └─────────────────┘

                    Docker network
                           │
              ┌────────────┴────────────┐
              ▼                         ▼
        WP files volume          DB data volume

```

Docker:
```
Host
│
├── Docker
│
├── Container
│   └── process
│
├── Container
│   └── process
│
└── Container
    └── process

```

```
docker-compose.yml

       ┌──────────┐
       │  nginx   │
       └────┬─────┘
            │
       ┌────▼─────┐
       │ wordpress│
       └────┬─────┘
            │
       ┌────▼─────┐
       │ mariadb  │
       └──────────┘

```
```
The Role of the Kernel

The kernel manages hardware resources and makes them available to software. CPU time, memory, and devices are central examples.

The kernel is the core component of an operating system. It acts as a bridge, allowing the hardware to communicate with the software. The kernel manages system resources, such as the CPU, memory, and peripheral devices. A complete operating system needs this resource-managing core in addition to the tools and applications people use.
```
```
Understanding Docker Concepts
Before we start using Docker, let's familiarize ourselves with some key concepts. Don't worry if they seem complex at first - we'll see them in action soon!

Container: A lightweight, standalone, and executable package that includes everything needed to run a piece of software.
Image: Think of this as a template or blueprint for containers. It contains all the instructions needed to create a container.
Docker Hub: Like GitHub but for Docker images - it's where you can find and share container images.
Docker Engine: The core technology that runs and manages containers on your machine.
This diagram shows that:

The Docker Engine runs containers
Images are used to create containers
Docker Hub stores images
The Docker Engine can pull images from Docker Hub and push images to Docker Hub

Let's break down what this command does:

docker: This is the command to interact with the Docker Engine.
run: This subcommand tells Docker to create and start a new container.
hello-world: This is the name of the image we want to run.
When you run this command, several things happen behind the scenes:

Docker checks if the hello-world image is available locally.
If not, it automatically downloads (or "pulls") the image from Docker Hub.
Docker creates a new container based on this image.
The container runs, displays a message, and then exits.

This output explains the process Docker went through to run the hello-world container. Let's break it down:

The Docker client (the command you ran) contacted the Docker daemon (the background service that manages Docker on your machine).
The daemon pulled the "hello-world" image from Docker Hub because it wasn't available locally.
The daemon created a new container from that image and ran it.
The container's output was sent back to your terminal.
Don't worry if you don't understand all of this yet. As we progress, these concepts will become clearer.
```

Best Practices for PID 1 in Containers
Use a minimal init system (like tini) to handle signals and zombies.
If your app is PID 1, ensure it handles SIGTERM, SIGINT, and reaps zombies.
Remember: When PID 1 exits, the container stops!
Summary
PID 1 is the “init” process in every Linux environment.
In servers/VMs, it’s always the system init (systemd, etc.).
In containers, your app becomes PID 1—with all its responsibilities!
Failing to manage PID 1 properly in containers can lead to unclean shutdowns and resource leaks.
Always test and experiment: Try running different apps as PID 1 in a container, and use process managers for production workloads.

```
Common Process Signals You Should Know

Here are the most common signals and what they do:

Signal 	Name 	Description

1 	SIGHUP 	Tells a program to restart (often used for daemons)
2 	SIGINT 	Interrupts the process (like pressing Ctrl + C)
9 	SIGKILL 	Forcefully kills the process—can’t be ignored
15 	SIGTERM 	Politely asks the process to terminate (default)
18 	SIGCONT 	Resumes a paused process
19 	SIGSTOP 	Pauses the process without killing it
```
Using killall for Convenience

Instead of using the PID, you can also send signals by name with killall:

```killall -SIGKILL firefox```

This will force quit all instances of Firefox. Very handy when an app is totally frozen. 

Signals Aren’t Just for Crashing Things

Not all signals are bad news! Some are meant to help programs behave better. For example:

    SIGHUP can make a server re-read its config file without stopping
    SIGSTOP and SIGCONT let you pause and resume tasks at will

It’s like having a remote control for your apps—you just need to know which button to press. 


```
Bonnes pratiques et multi-stage builds

    Choisir une image de base légère : privilégier les images Slim ou Alpine pour réduire la taille finale et la surface d’attaque.
    Regrouper les instructions RUN : combiner les commandes en une seule instruction RUN réduit le nombre de couches.
    Utiliser un fichier .dockerignore : exclure les fichiers inutiles (.git/, node_modules/, logs/) accélère le build et allège l’image.
    Ne jamais exécuter en root : toujours utiliser l’instruction USER avec un utilisateur dédié.
    Épingler les versions d’images : éviter le tag latest pour garantir la cohérence d’un build à l’autre.
    Optimiser l’ordre des instructions pour le cache : placer les instructions stables (ENV, WORKDIR, EXPOSE) en début de Dockerfile pour éviter d’invalider les couches inutilement.
```


TIPS:

1. reduce image size:
- start with small base image (ex: alpine instead of ubuntu)
- combine command with && (ex: RUN apt-get update && apt-get install ... && rm -rf /var/lib/apt/lists/*)
- clean up after installs 

2. Multi-stage builds:
multiple stages inside 1 dockerfile.
The first stage installs everything for building the app, compile it
the second stage grabs the output and copies it into a fresh clean image.
```
Dockerfile
   │
   ├── Stage 1: builder
   │
   └── Stage 2: runtime
              │
              ▼
            IMAGE
```

3. Add health checks to tell docker how to verify the container is healthy so orchastration tools like swarm or kubernetes can use these status to restart failing containers or reroot traffic

4. configure restart policies if a container exit with an error

5. docker config similar a secrets but for non sensitive data, html template, json_data... It mounts as a file in /config/










