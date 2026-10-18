# Agent Guidelines for Home Server Repository

This repository manages a home server infrastructure using Docker Compose and Ansible.
It contains service definitions, deployment configurations, and system provisioning playbooks.

## Project Structure

```
/home/emad/code/home/
├── compose.yaml              # Main compose file (includes services)
├── Makefile                  # make deploy / make env / make ansible
├── .env                      # Gitignored: deployment secrets fetched from the server (never committed)
├── services/                 # Individual service definitions
│   ├── template.yaml        # Service template
│   ├── traefik.yaml         # Reverse proxy
│   ├── gitlab.yaml          # GitLab CE
│   ├── kavita.yaml          # eBook reader
│   ├── n8n.yaml             # Workflow automation
│   ├── nextcloud.yaml       # Cloud storage and collaboration
│   ├── photoprism.yaml      # Photo management
│   ├── romm.yaml            # ROM manager/player (library: /home/emad/Games)
│   └── syncthing.yaml       # File synchronization
├── playbook.yaml            # Ansible system setup
└── inventory                # Ansible inventory
```

## Build & Deployment Commands

### Docker Compose Operations

```bash
# Deploy all services (fetches deployment secrets from the server first)
make deploy

# Only refresh the local .env from the server
make env

# Deploy all services (equivalent to what make deploy runs)
docker compose down
docker compose up -d --remove-orphans

# Deploy single service
docker compose down <service-name>
docker compose up -d <service-name>

# View logs
docker compose logs -f <service-name>

# Execute commands in containers
docker compose exec <service-name> <command>

# Check running services
docker compose ps
```

### Ansible Provisioning

```bash
# Run system setup playbook (requires sudo)
make ansible
# Equivalent to: ansible-playbook -i inventory --ask-become-pass playbook.yaml
```

### Remote Context

```bash
# Create remote docker context (one-time setup)
docker context create home --docker="host=ssh://home"

# Switch to remote context
docker context use home

# Return to local
docker context use default
```

## Code Style Guidelines

### Docker Compose Services

**Structure:** Each service follows this pattern:

```yaml
services:
  service-name:
    image: org/image:version          # Pin specific versions
    restart: unless-stopped           # Standard restart policy
    hostname: 'service.domain.com'    # Optional
    labels:                           # Traefik routing
      - "traefik.http.routers.name.rule=Host(`subdomain.home.emadelsaid.com`)"
      - "traefik.http.services.name.loadbalancer.server.port=8080"
    logging:
      driver: journald                # Centralized logging
    ports:                            # Only when bypassing Traefik
      - "host:container"
    volumes:
      - '/host/path:/container/path'
    environment:
      - 'VAR=value'
```

**Conventions:**

- **Image versions:** Always pin specific versions (e.g., `traefik:v3.1.2`), never use `latest`
- **Restart policy:** Use `restart: unless-stopped` for production services
- **Logging:** All services must use `driver: journald` for centralized logs
- **Traefik labels:** Required for HTTP services to be accessible via reverse proxy
- **Host paths:** Store persistent data in `/home/docker/services/<service-name>/`
- **Port exposure:** Only expose ports when service needs direct access (bypassing Traefik)
- **Comments:** Add operational comments for non-obvious commands (see gitlab.yaml examples)

**Naming:**

- Service names: lowercase, hyphenated (e.g., `gitlab-runner`)
- Hostnames: use format `service.home.emadelsaid.com`
- Router labels: match service name

### Ansible Playbooks

**Style:**

- Use YAML spacing: 2 spaces indentation
- Task names: Start with capital letter, descriptive
- Module format: Use FQCN (e.g., `community.general.pacman`)
- Privilege escalation: `become: true` per-task when needed
- Package lists: Use YAML list format for multiple items

**Example:**

```yaml
- name: Task description
  hosts: all
  tasks:
    - become: true
      ansible.builtin.service:
        name: service-name
        enabled: yes
        state: started
```

### Environment Variables & Secrets

**This repository is public. Never commit secrets.**

- **Default:** non-secret values are embedded directly in service YAML files, format `- 'KEY=value'` in the `environment:` section
- **Secrets:** real secrets (passwords, API keys, app secret keys) live in one file on the server, `/home/docker/.env` (mode `0600`, owned by the deploy user). That file is the single source of truth; there is no `.env` in the repo
- **Referencing them:** use a required-variable guard with a hint, so a missing value fails the deploy loudly instead of starting a container with an empty password:

  ```yaml
  environment:
    - 'DB_PASSWD=${ROMM_DB_PASSWORD:?run make env to fetch deployment secrets}'
  ```

- **Loading:** `docker compose` interpolates `.env` on the machine running the command, **not** on the daemon host, so a server-side file is never read directly. `make env` copies `/home/docker/.env` into the local gitignored `.env`; `make deploy` does that, then deploys. That is what makes deploying from any machine work
- **Adding a secret:** append `KEY=value` to `/home/docker/.env` on the server, then reference `${KEY:?...}` in the service YAML. Never put the value itself in the repo
- **Stability:** a database password in `.env` must keep matching what the container was first initialised with (e.g. MariaDB's data volume). Changing it means recreating the database, not just editing the file
- **Legacy:** some older services still embed credentials inline (e.g. nextcloud's `admin/admin`). Don't add more; move embedded secrets to the server `.env` when you touch those services

### File Organization

- **One service per file:** Each YAML file in `services/` contains one logical service group
- **Include pattern:** Main `compose.yaml` includes all service files
- **Template:** Use `services/template.yaml` as starting point for new services
- **Documentation:** Add comments for complex configurations or operational procedures

## Testing & Validation

```bash
# Validate compose syntax
docker compose config

# Validate specific service
docker compose config <service-name>

# Test service health
docker compose ps
docker compose logs <service-name>

# Ansible syntax check
ansible-playbook --syntax-check -i inventory playbook.yaml

# Ansible dry-run
ansible-playbook -i inventory --check playbook.yaml
```

## Common Operations

### Adding a New Service

1. Copy `services/template.yaml` to `services/<service-name>.yaml`
2. Update service configuration (image, volumes, environment, labels)
3. Add include line to `compose.yaml`
4. Deploy: `docker compose up -d <service-name>`

### Updating a Service

1. Modify service YAML file
2. Pull new image: `docker compose pull <service-name>`
3. Recreate: `docker compose down <service-name> && docker compose up -d <service-name>`

### Debugging

```bash
# Check container logs
docker compose logs -f --tail=100 <service-name>

# Inspect container
docker compose exec <service-name> sh

# Check Traefik dashboard
# Access: http://<server-ip>:8080

# View system logs (journald)
sudo journalctl -u docker -f
```

## Important Notes

- **Remote operations:** Ensure correct docker context when deploying
- **Timeouts:** Traefik configured with 3000s timeouts for large uploads
- **DNS:** Wildcard A record `*.server.emadelsaid.com` points to server internal IP
- **Security:** Services are internal-only; Traefik exposes them via HTTP (not HTTPS)
- **System requirements:** Ansible installs: docker, docker-compose, rsync, python, base-devel
