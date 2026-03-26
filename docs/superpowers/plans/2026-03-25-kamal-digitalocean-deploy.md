# Kamal + DigitalOcean Deployment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire up automatic deployment to a DigitalOcean Droplet via Kamal, triggered on every push to `master` after CI passes.

**Architecture:** GitHub Actions `deploy.yml` is triggered by `workflow_run` after the existing CI workflow succeeds on `master`. It runs `kamal deploy`, which builds the Docker image, pushes it to DigitalOcean Container Registry, SSHes into the Droplet, and performs a zero-downtime rolling restart. PostgreSQL and Redis run as Kamal accessories (managed Docker containers) on the same Droplet.

**Tech Stack:** Kamal 2, DigitalOcean Container Registry (DOCR), GitHub Actions `workflow_run`, Ruby 3.3, Rails 8, Solid Queue (runs inside Puma), PostgreSQL 16, Redis 7.

---

## Prerequisites (manual one-time steps — do these before running any tasks)

These are manual steps the user must complete in the DigitalOcean and GitHub UIs before the automated workflow will work.

**DigitalOcean:**
1. Create a Container Registry at https://cloud.digitalocean.com/registry — note the registry name (e.g. `personal-finance-agent`). The full server address will be `registry.digitalocean.com/<registry-name>`.
2. Generate a DigitalOcean API token at https://cloud.digitalocean.com/account/api/tokens with **read + write** scopes. This token is used for both registry auth and Kamal.
3. Confirm your Droplet's public IP address from https://cloud.digitalocean.com/droplets.
4. Make sure a domain (or subdomain) is pointed at the Droplet's IP via an A record (e.g. `app.yourdomain.com → <droplet-ip>`). This is required for Let's Encrypt SSL.
5. Make sure the SSH public key you'll use for deployment is in the Droplet's `~/.ssh/authorized_keys`. The easiest way: use the same key you already have in your DO account.

**GitHub:**
Add these repository secrets at `Settings → Secrets and variables → Actions → New repository secret`:

| Secret Name | Value |
|-------------|-------|
| `KAMAL_REGISTRY_PASSWORD` | Your DO API token |
| `SSH_PRIVATE_KEY` | The private key that pairs with the Droplet's authorized public key (full contents of `~/.ssh/id_ed25519` or similar) |
| `RAILS_MASTER_KEY` | Contents of `config/master.key` (never commit this file) |
| `PERSONAL_FINANCE_AGENT_DATABASE_PASSWORD` | A strong password you choose for the production Postgres DB (e.g. generate with `openssl rand -hex 32`) |

Also add one repository **variable** (not secret — it's not sensitive) at `Settings → Secrets and variables → Actions → Variables → New repository variable`:

| Variable Name | Value |
|---------------|-------|
| `DROPLET_IP` | Your Droplet's public IP address (e.g. `143.198.12.34`) |

---

## File Map

| File | Action | Purpose |
|------|--------|---------|
| `.kamal/secrets` | Modify | Read all secrets from ENV so they work in CI (no local key files) |
| `config/deploy.yml` | Modify | Set real DOCR registry, Droplet IP, SSL domain, Postgres + Redis accessories |
| `config/environments/production.rb` | Modify | Enable `assume_ssl` and `force_ssl` for SSL termination via Kamal proxy |
| `.github/workflows/deploy.yml` | Create | Deploy workflow triggered after CI passes on master |

---

## Task 1: Update .kamal/secrets to read from environment

**Files:**
- Modify: `.kamal/secrets`

This file is executed as a shell script by Kamal before deploying. Currently it reads `RAILS_MASTER_KEY` from `config/master.key` which doesn't exist in CI. Change it to read all secrets from environment variables instead — this works both in CI (where GitHub Actions injects them) and locally (where you export them in your shell).

- [ ] **Step 1: Replace .kamal/secrets content**

Open `.kamal/secrets` and replace the entire file with:

```bash
# Secrets are read from environment variables.
# In CI: set these as GitHub Actions secrets.
# Locally: export them in your shell before running kamal commands.

KAMAL_REGISTRY_PASSWORD=$KAMAL_REGISTRY_PASSWORD
RAILS_MASTER_KEY=$RAILS_MASTER_KEY
PERSONAL_FINANCE_AGENT_DATABASE_PASSWORD=$PERSONAL_FINANCE_AGENT_DATABASE_PASSWORD
```

- [ ] **Step 2: Verify the file looks correct**

```bash
cat .kamal/secrets
```

Expected output: the three lines above, no references to `config/master.key`.

- [ ] **Step 3: Commit**

```bash
git add .kamal/secrets
git commit -m "chore(deploy): read kamal secrets from env vars for CI compatibility"
```

---

## Task 2: Update config/deploy.yml with production values

**Files:**
- Modify: `config/deploy.yml`

Replace the placeholder `config/deploy.yml` with the fully configured production version. You must substitute three values that only you know:
- `YOUR_DROPLET_IP` → your Droplet's public IP (e.g. `143.198.12.34`)
- `YOUR_REGISTRY_NAME` → your DOCR registry name (e.g. `personal-finance-agent`)
- `YOUR_DOMAIN` → your domain/subdomain pointing at the Droplet (e.g. `app.yourdomain.com`)

- [ ] **Step 1: Replace config/deploy.yml**

Replace the entire file with the following, substituting your three values:

```yaml
# Name of your application. Used to uniquely configure containers.
service: personal_finance_agent

# Name of the container image.
image: registry.digitalocean.com/YOUR_REGISTRY_NAME/personal_finance_agent

# Deploy to these servers.
servers:
  web:
    - YOUR_DROPLET_IP

# Kamal proxy handles SSL termination via Let's Encrypt.
proxy:
  ssl: true
  host: YOUR_DOMAIN

# DigitalOcean Container Registry.
registry:
  server: registry.digitalocean.com/YOUR_REGISTRY_NAME
  username: YOUR_REGISTRY_NAME
  password:
    - KAMAL_REGISTRY_PASSWORD

# Environment variables injected into containers.
env:
  secret:
    - RAILS_MASTER_KEY
    - PERSONAL_FINANCE_AGENT_DATABASE_PASSWORD
  clear:
    SOLID_QUEUE_IN_PUMA: true
    DB_HOST: personal_finance_agent-db
    RAILS_LOG_LEVEL: info

# Build for amd64 (DigitalOcean Droplets run Linux/amd64).
builder:
  arch: amd64

# Persistent storage for Active Storage uploads.
volumes:
  - "personal_finance_agent_storage:/rails/storage"

# Bridge assets between deploys to avoid 404s on in-flight requests.
asset_path: /rails/public/assets

# Kamal CLI aliases.
aliases:
  console: app exec --interactive --reuse "bin/rails console"
  shell: app exec --interactive --reuse "bash"
  logs: app logs -f
  dbc: app exec --interactive --reuse "bin/rails dbconsole --include-password"

# Accessory services managed by Kamal on the Droplet.
accessories:
  db:
    image: postgres:16-alpine
    host: YOUR_DROPLET_IP
    port: "127.0.0.1:5432:5432"
    env:
      clear:
        POSTGRES_USER: personal_finance_agent
        POSTGRES_DB: personal_finance_agent_production
      secret:
        - PERSONAL_FINANCE_AGENT_DATABASE_PASSWORD
    directories:
      - data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    host: YOUR_DROPLET_IP
    port: "127.0.0.1:6379:6379"
    directories:
      - data:/data
```

- [ ] **Step 2: Verify no placeholders remain**

```bash
grep -E "YOUR_|192\.168|localhost:5555" config/deploy.yml
```

Expected: no output (all placeholders replaced).

- [ ] **Step 3: Commit**

```bash
git add config/deploy.yml
git commit -m "chore(deploy): configure kamal for digitalocean production deployment"
```

---

## Task 3: Enable SSL settings in production.rb

**Files:**
- Modify: `config/environments/production.rb`

The Kamal proxy handles SSL termination, so Rails must trust that all traffic arrives over HTTPS and enforce secure cookies. Two lines need to be uncommented.

- [ ] **Step 1: Uncomment assume_ssl**

In `config/environments/production.rb`, find:

```ruby
  # config.assume_ssl = true
```

Change to:

```ruby
  config.assume_ssl = true
```

- [ ] **Step 2: Uncomment force_ssl**

In `config/environments/production.rb`, find:

```ruby
  # config.force_ssl = true
```

Change to:

```ruby
  config.force_ssl = true
```

- [ ] **Step 3: Verify the changes**

```bash
grep -E "assume_ssl|force_ssl" config/environments/production.rb
```

Expected output:
```
  config.assume_ssl = true
  config.force_ssl = true
```

- [ ] **Step 4: Commit**

```bash
git add config/environments/production.rb
git commit -m "chore(deploy): enable ssl settings for kamal proxy termination"
```

---

## Task 4: Create the GitHub Actions deploy workflow

**Files:**
- Create: `.github/workflows/deploy.yml`

This workflow triggers when the CI workflow completes successfully on `master`. It installs Kamal (already in the Gemfile via `bin/kamal`), sets up the SSH agent with the deploy key from GitHub Secrets, then runs `kamal deploy`.

- [ ] **Step 1: Create .github/workflows/deploy.yml**

```yaml
name: Deploy

on:
  workflow_run:
    workflows: ["CI"]
    types: [completed]
    branches: [master]

jobs:
  deploy:
    runs-on: ubuntu-latest
    if: ${{ github.event.workflow_run.conclusion == 'success' }}

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true

      - name: Set up SSH agent
        uses: webfactory/ssh-agent@v0.9.0
        with:
          ssh-private-key: ${{ secrets.SSH_PRIVATE_KEY }}

      - name: Add Droplet to known hosts
        run: ssh-keyscan -H ${{ vars.DROPLET_IP }} >> ~/.ssh/known_hosts

      - name: Deploy with Kamal
        env:
          KAMAL_REGISTRY_PASSWORD: ${{ secrets.KAMAL_REGISTRY_PASSWORD }}
          RAILS_MASTER_KEY: ${{ secrets.RAILS_MASTER_KEY }}
          PERSONAL_FINANCE_AGENT_DATABASE_PASSWORD: ${{ secrets.PERSONAL_FINANCE_AGENT_DATABASE_PASSWORD }}
        run: bin/kamal deploy
```

- [ ] **Step 2: Verify the workflow file is valid YAML**

```bash
ruby -e "require 'yaml'; YAML.load_file('.github/workflows/deploy.yml'); puts 'Valid YAML'"
```

Expected output: `Valid YAML`

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/deploy.yml
git commit -m "feat(ci): add kamal deploy workflow triggered after ci passes on master"
```

---

## Task 5: Bootstrap the Droplet and do the first deploy

**Files:** none (one-time operational steps run from your local machine)

This task is run **once from your local machine**, not in CI. It installs Docker on the Droplet, starts the Kamal accessories (Postgres + Redis), and does the first full deploy. After this, all subsequent deploys happen automatically via GitHub Actions.

Before running these commands, make sure your local environment has the three secrets exported:

```bash
export KAMAL_REGISTRY_PASSWORD=<your-do-api-token>
export RAILS_MASTER_KEY=$(cat config/master.key)
export PERSONAL_FINANCE_AGENT_DATABASE_PASSWORD=<the-password-you-chose>
```

- [ ] **Step 1: Bootstrap Docker on the Droplet**

```bash
bin/kamal server bootstrap
```

Expected: Kamal SSHes in, installs Docker, and exits without errors.

- [ ] **Step 2: Start accessories (Postgres + Redis)**

```bash
bin/kamal accessory boot db
bin/kamal accessory boot redis
```

Expected: Each command exits with `Accessory db/redis booted` (or similar). Verify with:

```bash
bin/kamal accessory details db
bin/kamal accessory details redis
```

- [ ] **Step 3: Run the first full deploy**

```bash
bin/kamal setup
```

This builds and pushes the image, runs `db:migrate`, and starts the web container behind the Kamal proxy. Expected: finishes with `Finished all in X seconds` and no errors.

- [ ] **Step 4: Verify the app is live**

```bash
bin/kamal app logs
```

You should see Puma startup logs. Then open `https://YOUR_DOMAIN` in a browser — you should see the Rails app with a valid SSL certificate.

- [ ] **Step 5: Verify Solid Queue is running inside Puma**

```bash
bin/kamal app exec "bin/rails runner 'puts SolidQueue::Process.count'"
```

Expected: a number (≥ 1), confirming Solid Queue processes are registered.

---

## Verification: End-to-end deploy via GitHub Actions

After completing all tasks, verify the full automated flow works:

- [ ] Push a trivial change to `master` (e.g. add a comment to any file and commit)
- [ ] Watch the **CI** workflow run and pass in the GitHub Actions tab
- [ ] Watch the **Deploy** workflow trigger automatically after CI passes
- [ ] Confirm the Deploy workflow completes without errors
- [ ] Visit `https://YOUR_DOMAIN` and confirm the app is running the new code

If the Deploy workflow fails, check:
1. All 4 GitHub Secrets are set correctly (no trailing spaces, correct values)
2. The SSH private key has access to the Droplet (`ssh root@YOUR_DROPLET_IP` works locally)
3. The DOCR registry name in `config/deploy.yml` exactly matches the registry you created in DO
