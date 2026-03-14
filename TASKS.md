# TASKS.md

This file defines the incremental implementation tasks for the Personal Finance Agent.

Claude should only complete **one task at a time** and should not attempt to implement future tasks unless required for scaffolding.

Each task should leave the application in a **runnable state**.

---

# Phase 1 — Application Foundation

## Task 1.1 — Initialize Rails Application

Create a new Ruby on Rails application configured for the project.

Requirements:

- Ruby on Rails
- PostgreSQL
- Tailwind CSS
- Hotwire
- Devise authentication
- Sidekiq background jobs
- Redis job queue

Expected outcomes:

- Rails app boots successfully
- database configured
- authentication working
- Tailwind installed
- Sidekiq configured

---

## Task 1.2 — Base Layout

Create the base application layout.

Include:

- navigation bar
- dashboard entry page
- authentication pages
- Tailwind styling

Pages:

- `/dashboard`
- `/login`
- `/signup`

---

# Phase 2 — Core Data Models

## Task 2.1 — User Model

Ensure the User model includes:

Fields:

- email
- encrypted_password
- first_name
- last_name
- onboarding_completed_at

Relationships:

User has many:

- PlaidItems
- Accounts
- Transactions
- Insights
- Recommendations
- Reports
- Goals
- AgentRuns

---

## Task 2.2 — Financial Models

Create the following models and migrations:

### PlaidItem

Fields:

- user_id
- plaid_item_id
- access_token_encrypted
- institution_id
- institution_name
- last_sync_cursor
- last_synced_at

---

### Account

Fields:

- user_id
- plaid_item_id
- plaid_account_id
- name
- account_type
- account_subtype
- current_balance
- available_balance
- iso_currency_code

---

### Transaction

Fields:

- user_id
- account_id
- plaid_transaction_id
- amount
- name
- merchant_name
- pending
- authorized_date
- posted_date
- category_primary
- category_detailed
- raw_payload_json

---

# Phase 3 — Plaid Integration

## Task 3.1 — Plaid Client Setup

Install Plaid Ruby SDK.

Create: app/services/integrations/plaid_client.rb

This service should initialize the Plaid client using environment variables.

---

## Task 3.2 — Plaid Link Token Endpoint

Create a controller endpoint: POST /plaid/link_token

This endpoint should create a Plaid link token.

---

## Task 3.3 — Public Token Exchange

Create a controller endpoint: POST /plaid/exchange_public_token

Responsibilities:

- exchange public token
- store Plaid item
- store encrypted access token
- trigger initial sync job

---

## Task 3.4 — Transaction Sync Service

Create service: Plaid::SyncTransactions

Responsibilities:

- fetch transactions from Plaid
- upsert transactions
- update sync cursor
- store raw payload

---

# Phase 4 — Financial Analytics

Create deterministic analytics services.

## Task 4.1 — Category Breakdown

Service: Analysis::CategoryBreakdown

Responsibilities:

- compute category totals
- compute category percentages

---

## Task 4.2 — Merchant Breakdown

Service: Analysis::MerchantBreakdown

Responsibilities:

- compute merchant spend totals
- rank merchants by spending

---

## Task 4.3 — Recurring Charge Detection

Service: Analysis::RecurringChargeDetector

Responsibilities:

- detect repeating transactions
- estimate subscription cadence
- store recurring charges

---

## Task 4.4 — Spending Spike Detection

Service: Analysis::SpendingSpikeDetector

Responsibilities:

- detect abnormal spending
- compare to historical averages

---

# Phase 5 — Recommendations

## Task 5.1 — Savings Opportunity Estimator

Service: Planning::SavingsOpportunityEstimator

Responsibilities:

- identify top categories for reduction
- estimate potential savings

---

## Task 5.2 — Claude Recommendation Generator

Service: Planning::RecommendationGenerator

Responsibilities:

- send analytics summary to Claude
- generate structured recommendation JSON
- store Recommendation records

---

# Phase 6 — Reports

## Task 6.1 — Weekly Digest

Service: Reporting::WeeklyDigestGenerator

Responsibilities:

- summarize weekly spending
- highlight key changes
- generate report text

---

## Task 6.2 — Monthly Review

Service: Reporting::MonthlyReviewGenerator

Responsibilities:

- summarize monthly spending
- highlight trends
- generate recommendations summary

---

# Phase 7 — Background Jobs

Implement Sidekiq jobs.

## Jobs

- InitialPlaidSyncJob
- NightlyPlaidSyncJob
- FinancialAnalysisJob
- RecommendationGenerationJob
- WeeklyReportJob
- MonthlyReviewJob

Jobs should trigger the appropriate services.

---

# Phase 8 — User Interface

Create the primary application pages.

## Dashboard

Displays:

- monthly spend
- category breakdown
- top merchants
- most important insight
- top recommendation

---

## Action Plan

Displays:

- prioritized recommendations
- estimated savings
- rationale

---

## Subscriptions

Displays:

- recurring charges
- total recurring monthly cost

---

## Trends

Displays:

- spending changes
- category growth
- anomalies

---

## Reports

Displays:

- weekly reports
- monthly reviews

---

# Phase 9 — Scheduling

Add scheduled jobs.

Nightly jobs:

- Plaid transaction sync
- financial analysis

Weekly jobs:

- weekly digest

Monthly jobs:

- monthly review