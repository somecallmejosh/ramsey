# Clempo

**A multi-tenant personal-finance app for households that budget together.**

Clempo bundles four things a family actually uses to run its money into one app:

- **Envelope budgeting** — allocate a monthly budget per category and track spending against it
- **Debt snowball** — log debts and payments, watch payoff progress
- **AI meal planning** — Claude generates a week of meals (and a shopping list) from your preferences and pantry photos
- **Lunch tracker** — log packed work lunches and see the savings add up

Every household is its own tenant. One family's data is never visible to another, and that boundary is enforced in the architecture — not in a `where` clause someone has to remember.

> Live in production, serving real households. Access requires an invited account.

---

## Stack

| Layer | Choice |
| --- | --- |
| Framework | Ruby on Rails 8.1 (Ruby 3.2.2) |
| Database | PostgreSQL — four DBs in production (primary, cache, queue, cable) |
| Auth | Rails 8 native sessions + `has_secure_password` (bcrypt), no Devise |
| Background jobs | SolidQueue |
| Cache / Cable | SolidCache + SolidCable (database-backed) |
| AI | Claude `claude-sonnet-4-6` via the `anthropic` gem (multimodal — text + pantry photos) |
| Frontend | Hotwire (Turbo + Stimulus), ViewComponent, server-rendered |
| Styling | Tailwind CSS v4 (standalone CLI), centralized in a `UiPresenter` |
| Assets | Propshaft + importmap (no JS bundler) |
| Push | `web-push` (VAPID), PWA service worker + manifest |
| Testing | RSpec, FactoryBot, Shoulda Matchers, Capybara + headless Chrome, WebMock |
| Deploy | Kamal (Docker) |

---

## Getting started

### Prerequisites
- Ruby 3.2.2 (see `.ruby-version`)
- Node.js 22 (see `.nvmrc`) — used only to build Tailwind CSS
- PostgreSQL

### Setup

```bash
bundle install
npm install
bin/rails db:prepare        # create + migrate primary, cache, queue, cable DBs
```

### Run

```bash
bin/rails server            # http://localhost:3000
npm run watch:css           # compile Tailwind on change (separate terminal)
```

Create an account at `/registration/new`. The first user in an account is the **owner** and can access the `Admin::` namespace; owners invite additional members via token-based invitations.

### Environment

| Variable | Purpose |
| --- | --- |
| `CLAUDE_API_KEY` | Meal-plan generation via the Claude API |
| `RAMSEY_DATABASE_PASSWORD` | Production Postgres password |

VAPID keys for push notifications live in Rails encrypted credentials (`bin/rails credentials:edit`).

---

## Commands

```bash
# Testing
bundle exec rspec                              # full suite
bundle exec rspec spec/models/user_spec.rb     # one file
bundle exec rspec spec/models/user_spec.rb:42  # one example

# Linting & security
bin/rubocop -f github          # rubocop-rails-omakase style
bin/brakeman --no-pager        # static security scan
bin/bundler-audit              # gem vulnerability scan

# Assets
npm run build:css              # one-time Tailwind build
npm run watch:css              # watch mode

# Database
bin/rails db:migrate
bin/rails db:rollback
```

---

## Architecture

### Domain model

- **Envelope budgeting** — `Envelope` → `EnvelopeBudget` (per month/year) + `Expense` (transactions)
- **Debt snowball** — `Debt` → `DebtPayment`; tracks payoff progress
- **Meal planning** — `MealPlan` (a week) → `Meal` (a day) + `ShoppingItem`; AI-generated. Pantry images via Active Storage (S3 / Bunny CDN)
- **Lunch tracking** — `LunchLog`; logging a lunch pushes a notification to other account members
- **Multi-account** — `Account` groups users into a household; `Invitation` (token-based) lets owners add members. **All domain data is scoped to an account.**
- **Auth** — `User` + `Session`. Owner role gates the `Admin::` namespace via a `require_owner` concern.

### Layers

```
app/services/     business logic (MealPlannerService → Claude API)
app/jobs/         SolidQueue background work
app/queries/      query objects for complex reads
app/presenters/   presentation logic (incl. UiPresenter)
app/components/   ViewComponents (< ApplicationComponent)
```

### AI meal planning

`MealPlannerService` calls Claude via the `anthropic` gem. `MealPlannerJob` handles image encoding (HEIC → JPEG) and drives `MealPlan#status` through `pending → processing → ready | failed`. Tests stub the API with WebMock.

### Background jobs & cron

SolidQueue runs the jobs. Two endpoints are triggered by an **external** scheduler (Railway cron), not an in-app clock. Both require a Bearer token (`cron_secret`, stored in credentials):

- `POST /cron/monthly_rollover` — rolls envelope budgets into the new month
- `POST /cron/purge_unconfirmed_meal_plans` — cleans up abandoned meal plans

Other jobs: `NotifyAccountMembersJob` (push via `web-push`, notifies everyone but the actor), `MonthlyRolloverJob`, `PurgeUnconfirmedMealPlansJob`.

### Frontend

Tailwind v4 compiles to `app/assets/builds/`. Theme colors use an `hs-` prefix (`text-hs-primary`, `bg-hs-navy`). Interactivity is Turbo + Stimulus. **`UiPresenter` centralizes every Tailwind class string** — use `ui.button(:primary)` in views instead of inline classes.

### Multi-database

The Rails 8 Solid stack runs on separate databases for primary, cache (SolidCache), queue (SolidQueue), and cable (SolidCable) — see `config/database.yml`.

---

## Testing conventions

- RSpec + FactoryBot + Shoulda Matchers — **no fixtures, factories only**
- DatabaseCleaner: truncation for suite/JS specs, transaction otherwise
- System tests run Selenium headless Chrome (1400×900)
- Request specs sign in via `spec/support/auth_helpers.rb`

---

## Deployment

Kamal deploys the app as a Docker image. `RAILS_MASTER_KEY` comes from `config/master.key`.
