Home Server Configuration
==================================

This is a docker-compose and ansible configuration for my home server

# SSH config

Add the following to `~/.ssh/config` to connect to the server with `ssh home` instead of `ssh user@ip-address`

```
Host home
     HostName <server-ip-address>
     User <user-name>
```

# Docker context

To allow docker on your machine to control the docker instance on the home server add it as a context
```
docker context create home --docker="host=ssh://home"
```

Everytime you want to switch the context use
```
docker context use home
```

# Environment variables
docker compose files uses env variables if values are not set. to setup variables

* copy `.env.template` to `.env`
* edit `.env` to have the variables values
* load the file as you normally do. for me I'm using [autoenv](https://github.com/hyperupcall/autoenv)

# Deploy to remote server
```
docker compose down
docker compose up -d --remove-orphans
```

# Updating one service
```
docker compose down <service-name>
docker compose up -d <service-name>
```

# DNS

To make it easier to access containers add DNS A record to the internal server IP address with a wild card. Example:

- Type: A
- Domain: server.emadelsaid.com and *.server.emadelsaid.com
- IP: `my server internal IP`

# Ansible

It installs host system configuration and requirements needed by the containers.

```
make ansible
```
