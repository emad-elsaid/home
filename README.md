Home Server Configuration
==================================

This is a docker-compose configuration for my home server

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
