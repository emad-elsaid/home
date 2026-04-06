# Agent Guidelines for Home Server Repository

This repository manages a home server infrastructure using Docker Compose and Ansible.
It contains service definitions, deployment configurations, and system provisioning playbooks.

## Project Structure

```
/home/emad/code/home/
├── compose.yaml              # Main compose file (includes services)
├── services/                 # Individual service definitions
│   ├── template.yaml        # Service template
│   ├── traefik.yaml         # Reverse proxy
│   ├── photoprism.yaml      # Photo management
│   ├── gitlab.yaml          # GitLab CE
│   ├── syncthing.yaml       # File synchronization
│   ├── kavita.yaml          # eBook reader
│   ├── nextcloud.yaml       # Cloud storage and collaboration
│   └── ftp.yaml             # FTP service
├── playbook.yaml            # Ansible system setup
└── inventory                # Ansible inventory
```

## Build & Deployment Commands

### Docker Compose Operations

```bash
# Deploy all services
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

### Environment Variables

- **Embedded values:** Environment variables are embedded directly in service YAML files
- **Format:** `- 'KEY=value'` within the `environment:` section
- **No external files:** This repository does not use `.env` files; all configuration is in-service

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
