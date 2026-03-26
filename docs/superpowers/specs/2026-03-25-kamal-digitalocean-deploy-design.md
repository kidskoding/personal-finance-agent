# Kamal + DigitalOcean Deployment Design

**Date:** 2026-03-25
**Status:** Approved

## Overview

Automate deployment of the Personal Finance Agent Rails app to a DigitalOcean Droplet using Kamal, triggered by a push to `master` after CI passes.

## Deployment Flow

```
push to master
  → CI workflow passes (security scans + lint)
  → deploy workflow triggers
      → build Docker image (amd64)
      → push to DigitalOcean Container Registry (DOCR)
      → SSH into Droplet → kamal deploy
          → pull new image
          → run db:migrate
          → rolling restart (zero downtime)
```

## Components

### GitHub Actions Workflows

**Existing:** `.github/workflows/ci.yml`
Runs on push to master and PRs. Jobs: `scan_ruby`, `scan_js`, `lint`. No changes needed.

**New:** `.github/workflows/deploy.yml`
- Triggered by: `workflow_run` on CI workflow completing successfully on `master`
- Steps: checkout → install Kamal → set up SSH → `kamal deploy`

### config/deploy.yml (Kamal config)

Update from placeholder values to production:

- `registry.server`: `registry.digitalocean.com/<your-registry-name>`
- `registry.username`: `<DO_REGISTRY_TOKEN>`
- `servers.web`: real Droplet IP
- Add accessories: `db` (postgres:16) and `redis` (redis:7-alpine) managed by Kamal on the Droplet
- No separate job server needed — Solid Queue runs inside Puma via `SOLID_QUEUE_IN_PUMA: true`
- Enable SSL proxy with Let's Encrypt

### .kamal/secrets

Pulls secrets from environment at deploy time:
- `KAMAL_REGISTRY_PASSWORD` → DO registry token
- `RAILS_MASTER_KEY` → Rails master key
- `PERSONAL_FINANCE_AGENT_DATABASE_PASSWORD` → Postgres password

### GitHub Secrets Required

| Secret | Purpose |
|--------|---------|
| `DO_API_TOKEN` | DigitalOcean API token (registry push + auth) |
| `KAMAL_REGISTRY_PASSWORD` | DOCR password (same as DO API token) |
| `SSH_PRIVATE_KEY` | Private key for SSHing into Droplet |
| `RAILS_MASTER_KEY` | Rails credentials decryption key |
| `PERSONAL_FINANCE_AGENT_DATABASE_PASSWORD` | Postgres password for production DB |

## Services on the Droplet

Kamal manages all containers on a single Droplet:

| Container | Role |
|-----------|------|
| `personal_finance_agent-web` | Puma web server + Solid Queue (port 80/443) |
| `personal_finance_agent-db` | PostgreSQL 16 (Kamal accessory) |
| `personal_finance_agent-redis` | Redis 7 (Kamal accessory) |

## SSL

Kamal's built-in Traefik proxy handles Let's Encrypt SSL termination. Requires:
- A domain pointed at the Droplet IP
- `config/environments/production.rb` to have `config.assume_ssl = true` and `config.force_ssl = true`

## Prerequisites Before Deploy

1. Create a DigitalOcean Container Registry named (e.g. `personal-finance-agent`)
2. Droplet must have Docker installed (`kamal server bootstrap` handles this)
3. SSH public key added to Droplet's authorized_keys
4. Domain DNS pointed at Droplet IP
5. All GitHub Secrets set

## What Is Not Changing

- The existing CI workflow is unchanged
- The production Dockerfile is unchanged
- Rails app code is unchanged
