# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Prerequisites
- Ruby 3.2.2 (see `.ruby-version`)
- PostgreSQL
- Node.js (see `.nvmrc`)

## Commands

### Development
```bash
bin/rails server                          # Start dev server
bin/rails console                         # Rails console
npm run watch:css                         # Watch and compile Tailwind CSS
npm run build:css                         # One-time CSS build
```

### Testing
```bash
bundle exec rspec                         # All tests
bundle exec rspec spec/models/user_spec.rb                  # Single file
bundle exec rspec spec/models/user_spec.rb:42               # Single test by line
```

### Linting & Security
```bash
bin/rubocop -f github                     # Lint (rubocop-rails-omakase style)
bin/brakeman --no-pager                   # Security scan
bin/bundler-audit                         # Gem vulnerability scan
```

### Database
```bash
bin/rails db:migrate
bin/rails db:rollback
```

## Architecture

### Domain Model
- **Envelope budgeting**: `Envelope` → `EnvelopeBudget` (per month/year) + `Expense` (individual transactions)
- **Debt snowball**: `Debt` (name, type, balances, interest rate) → `DebtPayment` (individual payments); tracks payoff progress
- **Meal planning**: `MealPlan` (week) → `Meal` (day-level) + `ShoppingItem`; AI-generated via Claude API. Pantry images via Active Storage (S3/Bunny CDN)
- **Lunch tracking**: `LunchLog` (user logs daily work lunches; triggers account member push notification)
- **Multi-account**: `Account` groups users into households. `Invitation` (token-based) lets owners invite members. All domain data scoped to account.
- **Auth**: Rails 8 native auth — `User` + `Session` (bcrypt, no Devise). Owner role gates `Admin::` namespace via `require_owner` concern

### Layered Architecture
- `app/services/` — business logic (e.g., `MealPlannerService` calls Claude API)
- `app/jobs/` — background work via SolidQueue (`MealPlannerJob`, `MonthlyRolloverJob`, `NotifyAccountMembersJob`, `PurgeUnconfirmedMealPlansJob`)
- `app/queries/` — query objects for complex DB queries
- `app/presenters/` — presentation logic
- `app/components/` — ViewComponents (inherit `ApplicationComponent < ViewComponent::Base`)

### Claude API Integration
`MealPlannerService` calls `claude-sonnet-4-6` via the `anthropic` gem. API key comes from `ENV["CLAUDE_API_KEY"]`. The job (`MealPlannerJob`) handles image encoding (HEIC→JPEG) and updates `MealPlan#status` (`pending` → `processing` → `ready` | `failed`). Tests use WebMock to stub API responses.

### Frontend
- **Tailwind CSS v4** — compiled via npm scripts, output to `app/assets/builds/`. Theme colors use `hs-` prefix (e.g., `text-hs-primary`, `bg-hs-navy`)
- **Propshaft** (not Sprockets) + **importmap** (no bundler)
- **Turbo + Stimulus** for interactivity
- ViewComponents include `UiHelper`, `IconHelper`, `Turbo::FramesHelper` via `ApplicationComponent`
- **`UiPresenter`** centralizes Tailwind class strings for cards, buttons, inputs, modals, nav, etc. — use `ui.button(:primary)` in views instead of inline classes

### Background Jobs & Cron
SolidQueue runs jobs. Two cron endpoints exist at `POST /cron/monthly_rollover` and `POST /cron/purge_unconfirmed_meal_plans` — triggered externally (Railway cron or similar), not via ActiveJob scheduler.

### Push Notifications
`NotifyAccountMembersJob` uses the `web-push` gem with VAPID credentials stored in Rails encrypted credentials. Notifies all account members except the actor. Subscriptions stored in `push_subscriptions` table; expired ones are auto-pruned.

### Multi-Database (Rails 8 Solid Stack)
Separate DBs for primary, cache (SolidCache), queue (SolidQueue), and cable (SolidCable) — configured in `config/database.yml`.

### Testing Conventions
- RSpec + FactoryBot + Shoulda Matchers
- DatabaseCleaner: truncation strategy (suite/JS), transaction (normal specs)
- System tests use Selenium headless Chrome (1400×900)
- Request specs use `spec/support/auth_helpers.rb` for sign-in
- No fixtures — factories only

### Deployment
Kamal (Docker) deploys to production. `RAILS_MASTER_KEY` comes from `config/master.key`. Railway MCP server is configured in `.vscode/mcp.json` for Railway-related tooling.
