# Workshop Template Repo Design

**Date:** 2026-03-25
**Purpose:** A standalone GitHub template repository students use during the "100x Dev with Claude Code" workshop to build the Personal Finance Agent from scratch.

---

## Goal

Students fork this repo, follow along with the presenter, and walk away with a working Personal Finance Agent they built themselves using Claude Code.

---

## What the Repo Contains

### Core files (students start with these)

| File | Purpose |
|------|---------|
| `SPEC.md` | Product spec — what they're building |
| `CLAUDE.md` | Claude Code instructions — how to build it milestone by milestone |
| `README.md` | Workshop-specific setup guide (prereqs, how to use checkpoints) |
| `.env.example` | All required env vars with instructions |
| `Gemfile` + `Gemfile.lock` | All gems pre-configured so `bundle install` just works |
| `docker-compose.yml` | Runs Postgres, Redis, Rails, Sidekiq, Tailwind |
| `Dockerfile` + `Dockerfile.dev` | Container definitions |
| `Procfile.dev` | Local dev server (Rails + Sidekiq) |
| `.gitignore` | Standard Rails + project-specific ignores |

### Rails scaffold (rails new output only — no custom code)

- `app/` — empty skeleton (application_controller, application_record, application_job, layouts only)
- `config/` — base Rails config (database.yml, routes.rb, application.rb, etc.)
- `bin/` — Rails binstubs
- `public/` — static assets
- `lib/` — empty

**Nothing in `app/services/`, `app/models/` (beyond ApplicationRecord), `app/controllers/` (beyond ApplicationController), `app/jobs/` (beyond ApplicationJob), `db/migrate/`, or `spec/`.**

---

## Checkpoint Branches

The repo has 4 branches students can use to catch up if they fall behind:

| Branch | Contains |
|--------|---------|
| `main` | Starting point — scaffold + docs only |
| `checkpoint/milestone-1` | Rails foundation complete (Devise, Tailwind, Sidekiq, base layout) |
| `checkpoint/milestone-2` | Database schema complete (all migrations, models) |
| `checkpoint/milestone-3` | Plaid integration complete (link flow, token exchange, transaction sync) |
| `complete` | Full working app — all 8 milestones |

To catch up: `git merge checkpoint/milestone-N`

---

## Workshop Agenda (what the repo supports)

1. **Intro** (15 min) — presenter shows finished app, explains workflow
2. **Setup** (10 min) — clone repo, copy `.env.example` → `.env`, add keys, `docker compose up`
3. **Milestone 1** (20 min) — build Rails foundation together with Claude Code
4. **Milestones 2–3** (20 min) — schema + Plaid integration, connect sandbox account
5. **Merge complete branch** (15 min) — pull full app, explore with real data
6. **Q&A** (10 min)

---

## Prerequisites (communicated before the workshop)

Students must arrive with:
- Claude Code installed
- Docker installed and running
- Template repo cloned
- Plaid sandbox account + keys (dashboard.plaid.com — free)
- Anthropic API key (console.anthropic.com)

---

## What Needs to Be Built

1. **Strip this repo** down to the scaffold — remove all custom app code, migrations, specs
2. **Update `README.md`** to be workshop-specific (prereqs, agenda, checkpoint instructions)
3. **Update `CLAUDE.md`** if anything needs adjusting for a fresh-start context
4. **Add `RAILS_MASTER_KEY`** to `.env.example`
5. **Create checkpoint branches** at each milestone (requires building milestones 1–3 cleanly)
6. **Create `complete` branch** — points to the full working app code
7. **Push to new GitHub repo** marked as a Template Repository

---

## Out of Scope

- Slides or presenter materials (separate artifact)
- Hosting or deployment of the app
- Any changes to the application itself
