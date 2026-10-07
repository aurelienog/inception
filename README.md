*This project has been created as part of the 42 curriculum by aunoguei.*

# INCEPTION

## Table of Contents

## Description

## Instructions

## Resources

### Linux & system administration

[Files System](https://medium.com/aws-devops-simplified/understanding-the-linux-file-system-a-detailed-guide-d11784447747)
[Daemons TCP/IP](https://www.ibm.com/docs/es/aix/7.2.0?topic=protocol-tcpip-daemons)
[Processes](https://www.geeksforgeeks.org/linux-unix/processes-in-linuxunix/)
[Processes](https://medium.com/@nakuldesai123/understanding-the-linux-processes-basic-e6900de2454b)
[PID1](https://www.devopsschool.com/blog/understanding-pid-1-physical-servers-virtual-machines-and-containers/)
[PID1 - secure](https://dev.to/alanwest/why-your-docker-containers-refuse-to-die-the-pid-1-problem-e70)
[Signals](https://dev.to/axisinfo_0a61830e06c3c950/understanding-process-signals-in-linux-5gb)
[Cgroups](https://medium.com/@dmosyan/linux-cgroups-explained-how-containers-use-it-c99eebb8c9c6)
[Namespaces](https://medium.com/@teddyking/linux-namespaces-850489d3ccf)

### Docker concepts
[Guide](https://liora.io/docker-guide-complet)
[Container](https://docs.docker.com/get-started/docker-concepts/the-basics/what-is-a-container/)
[Image](https://docs.docker.com/get-started/docker-concepts/the-basics/what-is-an-image/)
[Registry](https://docs.docker.com/get-started/docker-concepts/the-basics/what-is-a-registry/)
[Docker Compose](https://docs.docker.com/compose)
[Compose file reference](https://docs.docker.com/reference/compose-file/)
[Networking in Compose](https://docs.docker.com/compose/how-tos/networking)
[Control in Compose](https://docs.docker.com/compose/how-tos/startup-order/)
[Networking](https://docs.docker.com/engine/network/)
[Bridge](https://docs.docker.com/engine/network/drivers/bridge/)
[Volumes](https://docs.docker.com/engine/storage/volumes/)
[Container & Ip](https://www.freecodecamp.org/espanol/news/como-obtener-la-direccion-ip-de-un-contenedor-docker-explicado-con-ejemplos/)
[Environment variables](https://docs.docker.com/compose/how-tos/environment-variables/)
[Secrets](https://docs.docker.com/engine/swarm/secrets/)
[Distroless images](https://docs.docker.com/dhi/explore/security-concepts/distroless/)
[Wasm workloads](https://docs.docker.com/desktop/features/wasm/)

### NGINX
[NGINX](https://nginx.org/index.html)
[NGINX SolarWinds Guides](https://www.papertrail.com/solution/guides/nginx/)
[NGINX guide](https://nginx.org/en/docs/beginners_guide.html)
[NGINX SSL Termination](https://docs.nginx.com/nginx/admin-guide/security-controls/terminating-ssl-http/)
[FastCGI Process Manager](https://www.php.net/install.fpm)
[fastcgi_pass](https://nginx.org/en/docs/http/ngx_http_fastcgi_module.html)

### SQL & others:
[SQL - Guide](https://liora.io/sql-tout-savoir)
[SQL - Tuto](https://sqlbolt.com/)
[MariaDB](https://mariadb.com/docs/server/reference/sql-statements/account-management-sql-statements/grant)
[WordPress](https://developer.wordpress.org/advanced-administration/wordpress/wp-config/?utm_source=chatgpt.com)
[debian - versions](https://cdimage.debian.org/cdimage/archive/)
[Docker tips](https://www.youtube.com/watch?v=EzUDAQGNUk8)

## Project description

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

bind mounts: map a specific directory on your host to a directory inside the container -> local development

```













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

3. Add health checks to tell docker how to verify the container is healthy so orchastration tools like swarm or kubernetes can use these status to restart failing containers or reroot traffic

4. configure restart policies if a container exit with an error

5. docker config similar a secrets but for non sensitive data, html template, json_data... It mounts as a file in /config/

6. tls certificates to secure?

7. in production:
    - use minimal base images to reduce attack surface
    - never run containers as root
    - enable resource limits (cpus, memory) in Dockerfile
    - log to stdout/stderr 