# SPEC.md

## Personal Finance Agent

### One-line description
Personal Finance Agent is a fully agentic personal finance application built with Ruby on Rails that connects to user bank accounts through Plaid, continuously analyzes spending behavior, detects wasteful patterns, and generates actionable recommendations and reports to help users cut down on spending.

---

## 1. Overview

Personal Finance Agent is an autonomous spending analysis and recommendation system.

The application is designed to help users understand where their money is going, identify unnecessary expenses, detect recurring subscriptions, surface abnormal spending patterns, and receive concrete recommendations for reducing monthly spend.

The system should work automatically in the background after financial data is synced. It should not depend on a conversational chatbot interface.

Users should open the app and immediately see:

- where their money is going
- what has changed recently
- what they should cut back on
- how much they could save
- what progress they have made over time

---

## 2. Goals

The application should help users:

- understand their spending patterns
- identify top spending categories
- detect recurring subscriptions and bills
- identify unusual spending spikes
- receive prioritized recommendations for reducing spending
- estimate realistic monthly savings opportunities
- track financial improvement over time
- receive weekly and monthly summaries automatically

---

## 3. Non-Goals

The application will not initially support:

- peer-to-peer payments
- direct bank transfers
- ACH initiation
- stock portfolio analysis
- tax preparation
- shared household budgeting
- manual envelope budgeting
- bill negotiation or cancellation integrations
- conversational chatbot UI
- mobile app clients

The MVP is focused on **spending analysis, savings recommendations, and autonomous financial reporting**.

---

## 4. Core Features

### 4.1 Bank Account Connection
Users connect financial institutions using Plaid Link.

The system must support:

- link token creation
- public token exchange
- secure Plaid item storage
- account syncing
- transaction syncing
- balance refreshes

### 4.2 Transaction Synchronization
Transactions should be imported and stored locally for analysis.

The system should support:

- initial transaction sync
- incremental sync
- transaction updates
- account balance refresh

### 4.3 Spending Analysis
The application should compute:

- monthly total spend
- spending by category
- spending by merchant
- week-over-week changes
- month-over-month changes
- largest transactions
- category growth trends

### 4.4 Subscription Detection
The system should detect likely recurring charges such as:

- streaming services
- SaaS subscriptions
- memberships
- recurring digital services
- recurring bills

The system should estimate total monthly recurring spend.

### 4.5 Spending Anomaly Detection
The system should identify unusual financial behavior, including:

- unusually expensive weeks
- sudden increases in a category
- abnormal merchant frequency
- one-off large transactions
- sudden changes versus prior periods

### 4.6 Savings Recommendations
The system should generate actionable recommendations such as:

- reducing restaurant spending
- reducing coffee spending
- reducing discretionary shopping
- canceling unnecessary subscriptions
- addressing large category increases

Each recommendation should include:

- a title
- a plain-English explanation
- supporting evidence
- estimated monthly savings
- priority or impact level

### 4.7 Financial Reports
The system should automatically generate:

#### Weekly reports
Short summaries of recent financial behavior, recent changes, and the most important next action.

#### Monthly reviews
Longer summaries including:

- where money went
- what changed from the previous month
- major recurring charges
- biggest savings opportunities
- progress against prior recommendations

### 4.8 Progress Tracking
The system should track whether the user is improving over time by comparing recent periods against prior recommendations and prior spending behavior.

---

## 5. Tech Stack

### Backend
- Ruby on Rails

### Frontend
- Rails views
- Hotwire
- Turbo
- Stimulus
- Tailwind CSS

### Database
- PostgreSQL

### Background Jobs
- Sidekiq
- Redis

### Financial Data Provider
- Plaid API
- Plaid Ruby client

### AI Reasoning Layer
- Claude API

Claude is used to convert structured financial analytics into user-facing recommendations and reports.

---

## 6. System Architecture

The application should be implemented as a standard Rails monolith.

Core architectural components:

- ActiveRecord models for domain data
- service objects for business logic
- Sidekiq jobs for background processing
- server-rendered views for the UI
- dedicated integration services for Plaid and Claude

The system should compute financial analytics deterministically in Ruby before invoking Claude for summaries or recommendations.

---

## 7. Domain Models

### 7.1 User
Represents an authenticated user.

Fields:
- email
- encrypted_password
- first_name
- last_name
- onboarding_completed_at

### 7.2 PlaidItem
Represents a connected financial institution.

Fields:
- user_id
- plaid_item_id
- access_token_encrypted
- institution_id
- institution_name
- last_sync_cursor
- last_synced_at
- sync_status

### 7.3 Account
Represents a bank account.

Fields:
- user_id
- plaid_item_id
- plaid_account_id
- name
- official_name
- mask
- account_type
- account_subtype
- current_balance
- available_balance
- iso_currency_code

### 7.4 Transaction
Represents a financial transaction.

Fields:
- user_id
- account_id
- plaid_transaction_id
- amount
- iso_currency_code
- name
- merchant_name
- payment_channel
- pending
- authorized_date
- posted_date
- category_primary
- category_detailed
- personal_finance_category_primary
- personal_finance_category_detailed
- raw_payload_json

### 7.5 RecurringCharge
Represents a detected recurring charge or subscription.

Fields:
- user_id
- merchant_name
- normalized_merchant_name
- average_amount
- min_amount
- max_amount
- cadence
- category
- active
- last_seen_at
- next_expected_at
- confidence_score
- source_transaction_ids_json

### 7.6 Insight
Represents a detected financial pattern.

Examples:
- spending spike
- recurring charge detected
- category growth
- merchant concentration
- improvement
- regression

Fields:
- user_id
- insight_type
- title
- summary
- severity
- confidence_score
- period_start
- period_end
- supporting_data_json

### 7.7 Recommendation
Represents an actionable financial recommendation.

Fields:
- user_id
- insight_id
- title
- description
- rationale
- estimated_monthly_savings
- priority
- impact_level
- status
- recommendation_type
- supporting_data_json

### 7.8 ActionPlan
Represents a grouped plan of recommendations for a period.

Fields:
- user_id
- title
- summary
- status
- total_estimated_monthly_savings
- period_start
- period_end
- generated_at

### 7.9 ActionPlanItem
Joins action plans to recommendations.

Fields:
- action_plan_id
- recommendation_id
- rank

### 7.10 Report
Represents a generated weekly or monthly report.

Fields:
- user_id
- report_type
- title
- body_markdown
- period_start
- period_end
- generated_at

### 7.11 Goal
Represents a user savings goal.

Fields:
- user_id
- goal_type
- target_amount
- period
- active

### 7.12 AgentRun
Represents one autonomous analysis cycle.

Fields:
- user_id
- trigger_type
- status
- started_at
- completed_at
- input_snapshot_json
- output_summary_json

---

## 8. Relationships

- User has many PlaidItems
- User has many Accounts
- User has many Transactions
- User has many RecurringCharges
- User has many Insights
- User has many Recommendations
- User has many ActionPlans
- User has many Reports
- User has many Goals
- User has many AgentRuns

- PlaidItem belongs to User
- PlaidItem has many Accounts

- Account belongs to User
- Account belongs to PlaidItem
- Account has many Transactions

- Transaction belongs to User
- Transaction belongs to Account

- Recommendation belongs to User
- Recommendation belongs to Insight, optional

- ActionPlan belongs to User
- ActionPlan has many ActionPlanItems
- ActionPlan has many Recommendations through ActionPlanItems

---

## 9. Core Services

### 9.1 Plaid Services
- `Plaid::CreateLinkToken`
- `Plaid::ExchangePublicToken`
- `Plaid::SyncAccounts`
- `Plaid::SyncTransactions`
- `Plaid::RefreshBalances`

### 9.2 Analysis Services
- `Analysis::CategoryBreakdown`
- `Analysis::MerchantBreakdown`
- `Analysis::PeriodComparison`
- `Analysis::RecurringChargeDetector`
- `Analysis::SpendingSpikeDetector`
- `Analysis::LargestTransactions`

### 9.3 Planning Services
- `Planning::SavingsOpportunityEstimator`
- `Planning::RecommendationGenerator`
- `Planning::ActionPlanBuilder`

### 9.4 Reporting Services
- `Reporting::WeeklyDigestGenerator`
- `Reporting::MonthlyReviewGenerator`
- `Reporting::ProgressSummaryGenerator`

### 9.5 Integration Services
- `Integrations::PlaidClient`
- `Integrations::ClaudeClient`

---

## 10. Background Jobs

The system should use Sidekiq jobs to automate data sync, analysis, and reporting.

### 10.1 InitialPlaidSyncJob
Runs after the user connects a bank account.

Responsibilities:
- sync accounts
- sync transactions
- trigger downstream analysis

### 10.2 NightlyPlaidSyncJob
Runs nightly for connected users.

Responsibilities:
- refresh balances
- sync new transactions
- trigger analysis if new data exists

### 10.3 FinancialAnalysisJob
Runs deterministic analytics on synced transaction data.

Responsibilities:
- category aggregation
- merchant aggregation
- comparison calculations
- subscription detection
- anomaly detection

### 10.4 RecommendationGenerationJob
Builds financial recommendations and action plans.

### 10.5 WeeklyReportJob
Generates weekly financial digests.

### 10.6 MonthlyReviewJob
Generates monthly review reports.

### 10.7 ProgressTrackingJob
Evaluates changes over time and updates progress insights.

---

## 11. Main Pages

### 11.1 Dashboard
Displays:
- total spend this month
- top spending categories
- top merchants
- most important insight
- top savings opportunity
- recent changes

### 11.2 Action Plan
Displays:
- prioritized recommendations
- estimated monthly savings
- impact level
- rationale for each recommendation

### 11.3 Subscriptions
Displays:
- recurring charges
- likely subscriptions
- total recurring monthly spend
- likely cancellation targets

### 11.4 Trends
Displays:
- spending changes over time
- category shifts
- anomalies
- major growth areas

### 11.5 Reports
Displays:
- weekly reports
- monthly reviews
- historical summaries

### 11.6 Progress
Displays:
- improvements over time
- regressions
- prior recommendations
- estimated savings progress

---

## 12. Data Flow

1. User signs up and logs in
2. User connects a bank account via Plaid
3. The backend exchanges the public token for an access token
4. The system stores the encrypted Plaid item and syncs accounts
5. Transactions are imported and stored locally
6. Financial analysis jobs compute structured summaries
7. Claude converts structured summaries into recommendations and reports
8. Recommendations, reports, and action plans are stored
9. The UI displays the latest financial insights and recommendations

---

## 13. Security and Privacy

The application must:

- encrypt Plaid access tokens at rest
- require authentication for all financial pages
- isolate user financial data
- avoid logging sensitive financial payloads
- avoid exposing raw Plaid credentials
- use HTTPS in deployed environments
- clearly communicate what data is stored and analyzed

---

## 14. Milestones

### Milestone 1: App Foundation
- Rails setup
- Devise authentication
- Tailwind CSS
- Hotwire
- Sidekiq
- Redis
- PostgreSQL configuration
- base layout
- dashboard shell

### Milestone 2: Plaid Integration
- link token creation
- public token exchange
- Plaid item storage
- account syncing
- transaction syncing

### Milestone 3: Financial Analytics
- category aggregation
- merchant aggregation
- recurring detection
- anomaly detection
- period comparisons

### Milestone 4: Recommendation System
- savings opportunity estimation
- recommendation generation
- action plan creation

### Milestone 5: Reporting
- weekly digest generation
- monthly review generation
- progress summary generation

### Milestone 6: UI Implementation
- dashboard
- action plan page
- subscriptions page
- trends page
- reports pages
- progress page

### Milestone 7: Scheduling and Polish
- recurring jobs
- loading states
- empty states
- error states
- seed/demo data
- responsive polish