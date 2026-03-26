# Ramsey — Project Plan

A family budget and meal planning app for Josh and Sally Briley.
Built with Ruby on Rails 8, Hotwire, Stimulus, Tailwind CSS, and PostgreSQL. Hosted on Railway.

---

## Decisions log

| Question             | Decision                                                                                                                                                                                                                                                                                                                         |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Domain               | `ramsey.thebrileys.com` — custom domain configured in Railway                                                                                                                                                                                                                                                                    |
| Auth                 | Separate logins per person via Rails 8 auth generator. Josh: admin role. Sally: standard role.                                                                                                                                                                                                                                   |
| Roles                | Two levels only — admin (Josh) and standard (Sally). Role controls access to envelope management and settings. Sally's UI has no settings link and cannot reach admin routes.                                                                                                                                                    |
| Simultaneous editing | Accepted risk in v1. Last-write-wins. Real-world collision risk is low for a two-person app. Turbo Streams broadcast via Action Cable is a v2 addition if needed.                                                                                                                                                                |
| PWA                  | Yes. Configured at project setup so Sally can add to iPhone home screen from day one.                                                                                                                                                                                                                                            |
| Meal plan seeding    | No manual seed data. The AI chat generates the first week's plan.                                                                                                                                                                                                                                                                |
| AI meal planning     | Yes. Claude API chat interface. Sally describes what she has and what she needs. The `MealPlan` (draft) record is saved immediately so Active Storage can attach pantry images; `confirmed_at` is null until Sally confirms. `Meal` and `ShoppingItem` records are only written on confirmation.                                 |
| Deployment           | Traditional Rails install on Railway. No Docker, no Kubernetes, no containerization. Railway builds and deploys from the Git repository directly using its native Ruby/Rails buildpack.                                                                                                                                          |
| File storage         | S3-compatible object storage (Tigris or AWS S3) configured via Active Storage before Phase 3. Railway's ephemeral filesystem is wiped on every redeploy — pantry photos stored there would be lost after each deploy. Configure `config/storage.yml` with S3 credentials in Rails credentials before adding `has_many_attached`. |

---

## What this app does

Ramsey replaces the paper-and-pen envelope tracking system and disconnected meal planning process with a single, shared web app accessible at `ramsey.thebrileys.com`. Both Josh and Sally access it from any browser. It is configured as a Progressive Web App so it can be added to the iPhone home screen and behaves like a native app.

The app focuses exclusively on food and cash envelopes. It does not replace the full budget spreadsheet for fixed expenses and savings tracking.

---

## Envelopes tracked

| Envelope           | Monthly budget |
| ------------------ | -------------- |
| Groceries          | $700           |
| Restaurants        | $150           |
| Work meals         | $100           |
| Gas                | $300           |
| Clothing           | $75            |
| Entertainment      | $75            |
| Blow money — Josh  | $50            |
| Blow money — Sally | $50            |
| Hygiene            | $50            |
| **Total**          | **$1,550**     |

---

## Features

### 1. Envelope tracker

The highest-priority feature. Replaces paper and pen immediately.

- View all active envelopes on a single dashboard
- See this month's budget, amount spent, and amount remaining per envelope
- Log a transaction in three taps: tap envelope, enter amount, confirm
- Envelopes reset automatically on the 1st of each month
- All transactions timestamped and attributed to Josh or Sally
- Month selector to review prior months

**Prior month access policy:**

| Action                                | Sally (standard) | Josh (admin) |
| ------------------------------------- | ---------------- | ------------ |
| View prior month transactions         | ✓                | ✓            |
| View prior month meal plans           | ✓                | ✓            |
| Add a transaction to a prior month    | —                | ✓            |
| Delete/edit a prior month transaction | —                | ✓            |
| Edit a prior month envelope budget    | —                | Never        |

Prior month envelope budgets are permanently read-only for all users. The historical budget record is never modified — only corrected by adding or removing individual transactions. The `prior_month?` check is enforced at both the controller and model level:

```ruby
# app/models/envelope_budget.rb
before_update :prevent_prior_month_modification

private

def prior_month?
  Date.new(year, month) < Date.current.beginning_of_month
end

def prevent_prior_month_modification
  if prior_month?
    errors.add(:base, "Cannot modify a prior month's budget")
    throw(:abort)
  end
end
```

The controller scope (`transacted_on < Date.current.beginning_of_month`) provides the first line of defense. The model callback provides defense in depth, protecting against direct `ActiveRecord` calls in tests, background jobs, or the Rails console.

**Budget management (settings screen, admin only):**

- Edit any envelope's budget amount for the current month without affecting prior months
- Add a new envelope at any time — enter a name and this month's budget amount
- Deactivate an envelope to remove it from the dashboard while preserving all historical transaction data
- Budget amounts carry forward automatically each month as defaults, so you only update what changes

### 2. AI meal planner chat

Sally opens a chat window and describes what she has and what she needs in plain language. She can also upload photos of the pantry and freezer. The app sends her message, any images, and household context to the Claude API and returns a complete seven-day meal plan and shopping list. Sally reviews and confirms before anything saves to the database.

Example inputs the chat handles:

- "Create a menu for this week. We already have 3 lbs of chicken breasts, two pounds of ground meat, and three bags of frozen vegetables."
- "I need a shopping list and a plan for meals this week." [with pantry and freezer photos attached]
- "We're really busy this week, make it simple. Kayla won't eat fish."

**Image upload:** Sally can attach one or more photos directly in the chat window — a shot of the pantry, the freezer, or both. The API call includes the images encoded as base64 alongside her text message. Claude reads the visible contents and factors them into the meal plan, reducing the shopping list to only what's actually needed. The confirm-before-save preview lets Sally catch anything the AI misread in a dimly lit or cluttered photo before it affects her plan.

The Claude API call includes the following context automatically so Sally does not have to repeat it each time:

- Family of three (Josh, Sally, Kayla)
- Grocery envelope remaining balance for the current week
- Aldi-first shopping strategy
- Any pantry items Sally mentions in her message or visible in uploaded photos

The response returns structured JSON — seven meals with dinner, lunch, prep note, and estimated cost per day, plus a shopping list with name, quantity, and estimated cost per item. The app renders this as a preview. Sally can edit individual meals before confirming. On confirm, the records save to the database.

### 3. Weekly meal plan view

- Seven-day view of the confirmed meal plan
- Dinner and lunch per day, prep note, estimated dinner cost
- Edit individual meals after the AI generates them
- Week navigation to view prior weeks

### 4. Shopping list

- Generated from the confirmed meal plan
- Manually add items not tied to a meal
- Checkbox to mark items as purchased in-store
- Running estimated total visible while shopping
- Groceries envelope remaining balance shown alongside the cart total
- Warning when estimated cart total exceeds remaining envelope balance
- "Log this shop" button — pre-fills a grocery transaction with the total of checked items, two-tap confirm

### 5. Budget vs. actual graph

- Bar graph on the groceries envelope detail page
- Eight weeks of history against the $175/week target ($700 ÷ 4)
- Monthly summary stat: spend to date vs. $700 target
- Updates automatically as transactions are logged

### 6. Work lunch tracker

- Weekly grid: Monday through Friday, packed or not packed per day
- One tap to toggle
- Monthly running stats: days packed, estimated savings, remaining work meals envelope balance
- Default savings value per packed lunch: $8

---

## Data model

### `users`

Built by the Rails 8 auth generator. Two records — one per person.

```
id
email_address       string
password_digest     string
role                integer       enum — 0 = standard (default), 1 = admin
created_at
updated_at
```

```ruby
# app/models/user.rb
enum :role, { standard: 0, admin: 1 }, default: :standard
```

Seeded records:

- Josh — `role: :admin` — full access including envelope management and settings
- Sally — `role: :standard` — transaction logging, meal planning, shopping list, read access to all data

**Authorization:** A `RequireAdmin` controller concern guards all admin routes with a `before_action`. Standard users are redirected to root if they attempt to access a protected path directly. The settings link does not appear in Sally's navigation at all.

```ruby
# app/controllers/concerns/require_admin.rb
module RequireAdmin
  extend ActiveSupport::Concern

  # The concern intentionally does NOT include an `included do` block.
  # Do NOT add `before_action :require_admin_role` here — that would apply it to all
  # actions automatically on include, requiring skip_before_action everywhere else.
  # Instead, call `before_action :require_admin_role, only: [...]` explicitly in each
  # controller that includes this concern. Authorization is opt-in and visible at the
  # point of declaration.

  private

  def require_admin_role
    redirect_to root_path unless current_user.admin?
  end
end
```

**Applying the concern:** Include `RequireAdmin` in a controller to gain the `require_admin_role` private method, then declare `before_action :require_admin_role, only: [...]` explicitly. This keeps authorization opt-in and auditable:

```ruby
# EnvelopesController — index and show are open to both users; write actions are admin-only
before_action :require_admin_role, only: [:new, :create, :edit, :update, :destroy]

# EnvelopeBudgetsController — only update is restricted
before_action :require_admin_role, only: [:update]

# SettingsController — all actions are admin-only
before_action :require_admin_role
```

**Avoid the `skip_before_action` anti-pattern:** Do not `include RequireAdmin` at the class level and then `skip_before_action :require_admin_role, only: [:index, :show]`. With the skip approach, any new action added to the controller is silently admin-only until someone remembers to add it to the skip list. The failure mode is invisible access restriction. The explicit `only:` approach above makes authorization visible at the point of declaration.

### `envelopes`

Identity record only — no budget amount stored here. Budget amounts live in `envelope_budgets` so they can vary month to month.

**Association `dependent:` declarations:**

```ruby
# app/models/envelope.rb
has_many :envelope_budgets, dependent: :destroy
has_many :expenses, dependent: :destroy

# app/models/meal_plan.rb
has_many :meals, dependent: :destroy
has_many :shopping_items, dependent: :destroy
has_many_attached :pantry_images, dependent: :purge_later  # Must be explicit — Rails does NOT set this automatically; without it, destroying a MealPlan leaves orphaned blobs in S3

# app/models/user.rb
has_many :expenses, dependent: :destroy
has_many :meal_plans, dependent: :destroy
has_many :lunch_logs, dependent: :destroy
has_many :push_subscriptions, dependent: :destroy
```

Without these, calling `.destroy` on a parent in the Rails console or in tests silently orphans all child records. Add `dependent:` to every `has_many` before writing any data.

```
id
name                string        e.g. "Groceries"
position            integer       display order
active              boolean       default true
created_at
updated_at
```

`active: false` is a soft delete. The envelope disappears from the dashboard but all transaction history is preserved and remains queryable. Historical graphs and monthly summaries continue to show data for deactivated envelopes.

### `envelope_budgets`

One record per envelope per month. This is what the app reads when calculating "budget" for any given month.

```
id
envelope_id         references    not null
year                integer       not null   e.g. 2026
month               integer       not null   1–12
amount              decimal       precision: 10, scale: 2, null: false
created_at
updated_at

index [:envelope_id, :year, :month], unique: true
```

Add model-level validations to match the database constraint and guard against bad data:

```ruby
# app/models/envelope_budget.rb
validates :month, uniqueness: { scope: [:envelope_id, :year] }
validates :amount, numericality: { greater_than_or_equal_to: 0 }
```

The uniqueness validation at the model level produces a handled `ActiveRecord::RecordInvalid` instead of a raw `ActiveRecord::RecordNotUnique` from the database. The `upsert_all` in the rollover job bypasses validations intentionally (it is idempotent by design), but direct `EnvelopeBudget.create` calls elsewhere are protected.

**Monthly rollover logic:** On the 1st of each month, a Railway cron job triggers the rollover. Railway cron calls an HTTP endpoint, so the app exposes a dedicated controller action for this:

```ruby
# app/controllers/cron_controller.rb
class CronController < ApplicationController
  skip_before_action :require_authentication, only: [:monthly_rollover, :purge_unconfirmed_meal_plans]   # Railway POSTs as an unauthenticated HTTP request — skip session auth and replace with token auth below
  skip_before_action :verify_authenticity_token, only: [:monthly_rollover, :purge_unconfirmed_meal_plans]  # Restrict skips to specific actions so any future actions added here don't silently inherit open access
  before_action :authenticate_cron_token

  # POST /cron/monthly_rollover
  def monthly_rollover
    MonthlyRolloverJob.perform_later
    head :ok
  end

  # POST /cron/purge_unconfirmed_meal_plans
  def purge_unconfirmed_meal_plans
    PurgeUnconfirmedMealPlansJob.perform_later
    head :ok
  end

  private

  def authenticate_cron_token
    secret = Rails.application.credentials.cron_secret
    head :unauthorized and return if secret.blank?

    # `and return` is required — `head :unauthorized` renders a response but does NOT halt
    # the before_action chain by itself. Without the explicit return, the controller action
    # executes even after rendering :unauthorized.
    head :unauthorized and return unless ActiveSupport::SecurityUtils.secure_compare(
      request.headers["Authorization"].to_s,
      "Bearer #{secret}"
    )
  end
end
```

Add a startup initializer to fail loudly if `cron_secret` is missing rather than silently accepting any request:

```ruby
# config/initializers/required_credentials.rb
Rails.application.config.after_initialize do
  next if Rails.env.test?  # Tests mock external services — credentials are not needed and RAILS_MASTER_KEY is not set in CI

  %i[claude_api_key cron_secret vapid_public_key vapid_private_key].each do |key|
    if Rails.application.credentials.send(key).blank?
      raise "Missing required credential: #{key}. Run `rails credentials:edit` to set it."
    end
  end
end
```

The `MonthlyRolloverJob` is idempotent: it uses `upsert_all` with `unique_by:` instead of `find_or_create_by` so a Railway double-fire cannot produce duplicate records — two concurrent calls collapse to one write:

````ruby
# app/jobs/monthly_rollover_job.rb
class MonthlyRolloverJob < ApplicationJob
  def perform
    today      = Date.current  # Capture once — job runs at midnight; multiple calls could straddle a day boundary
    year       = today.year
    month      = today.month
    last_month = today.last_month

    records = EnvelopeBudget
      .where(year: last_month.year, month: last_month.month)
      .joins(:envelope)
      .merge(Envelope.where(active: true))
      .map do |eb|
        { envelope_id: eb.envelope_id, year: year, month: month,
          amount: eb.amount, created_at: Time.current, updated_at: Time.current }
      end

    EnvelopeBudget.upsert_all(records, unique_by: [:envelope_id, :year, :month]) if records.any?
  end
end
``` The job copies last month's `EnvelopeBudget` amounts as defaults for each active envelope. Josh or Sally can then edit any budget via the settings screen. Changes apply only to the current month. Prior months are never modified retroactively.

Store `cron_secret` in Rails credentials (`rails credentials:edit`). Configure the Railway cron to `POST /cron/monthly_rollover` with the `Authorization: Bearer <token>` header.

**New envelope mid-year:** Adding an envelope creates the `Envelope` record and a single `EnvelopeBudget` record for the current month. The app prompts for a budget amount at creation time.

### `expenses`
Core of the envelope tracker.

> **Note:** This model is named `Expense` (table: `expenses`), not `Transaction`. Rails defines a class-level `transaction` method on all `ActiveRecord::Base` subclasses — a model named `Transaction` makes `Transaction.transaction do` genuinely ambiguous and the AR method wins. `Expense` eliminates this collision entirely.

````

id
envelope_id references not null
user_id references not null — the user who logged this expense
amount decimal precision: 10, scale: 2, null: false
note string optional
transacted_on date not null
created_at
updated_at

````

`user_id` replaces the former `logged_by` string column. Use `expense.user` for attribution and display the user's name via a helper or model method rather than storing a raw string.

Add model validations to prevent $0/negative entries and future-dated transactions from silently corrupting envelope balances:
```ruby
# app/models/expense.rb
validates :amount, numericality: { greater_than: 0 }
validates :transacted_on, comparison: { less_than_or_equal_to: -> { Date.current },
                                         message: "cannot be a future date" }
````

### `meal_plans`

One record per week.

```
id
user_id             references    not null — the user who generated this plan
week_start          date          always a Sunday
confirmed_at        datetime      null until Sally confirms the AI preview
created_at
updated_at
```

Active Storage attachment: `has_many_attached :pantry_images` — stores photos Sally uploads during the planning chat. Images are sent to the Claude API at plan generation time and retained for reference. Storage backend: S3-compatible bucket (see Active Storage decision in the decisions log).

**Orphaned blob cleanup:** When Sally generates a preview but closes the tab without confirming, the `MealPlan` record IS saved immediately (Active Storage requires a persisted record to attach blobs), but `confirmed_at` remains null. Add a scheduled cleanup job to purge `MealPlan` records where `confirmed_at IS NULL AND created_at < 24.hours.ago`.

**Retry pattern:** Because a `MealPlan` record is persisted at generation time, and the `week_start` index is unique, generating a second plan for the same week within the same day requires destroying the existing unconfirmed draft first. The `MealPlansController#create` action must check for an existing unconfirmed plan for the requested `week_start` and destroy it before creating the new one. Do not rely on the nightly cleanup job for this — Sally needs to be able to retry immediately if the first result is unsatisfactory.

```ruby
# app/jobs/purge_unconfirmed_meal_plans_job.rb
class PurgeUnconfirmedMealPlansJob < ApplicationJob
  def perform
    MealPlan.where(confirmed_at: nil).where("created_at < ?", 24.hours.ago).find_each do |plan|
      plan.destroy  # dependent: :purge_later on has_many_attached handles blob cleanup automatically
      # Do NOT call plan.pantry_images.purge_later before destroy — the dependent: callback fires
      # on destroy and would schedule two purge jobs per image.
    end
  end
end
```

Schedule this job nightly via a second Railway cron entry. The `CronController` handles it with a dedicated `purge_unconfirmed_meal_plans` action (see the `CronController` in the `EnvelopeBudgets` section).

**`week_start` validation:** `week_start` must always be a Sunday. A console typo or a controller bug that saves a non-Sunday date breaks the entire weekly view logic — guard it at the model level:

```ruby
# app/models/meal_plan.rb
validates :week_start, presence: true
validates :week_start, uniqueness: true  # one plan per week for the household; model-level validation
                                          # produces a handled RecordInvalid instead of a raw DB constraint error
validate :week_start_must_be_sunday
validate :confirmed_at_not_cleared_after_set

private

def confirmed_at_not_cleared_after_set
  if confirmed_at_was.present? && confirmed_at.nil?
    errors.add(:confirmed_at, "cannot be cleared after confirmation")
  end
end


def week_start_must_be_sunday
  return if week_start.blank?
  errors.add(:week_start, "must be a Sunday") unless week_start.sunday?
end
```

**File validation:** Validate uploaded files at the model level to prevent non-image uploads from reaching the Claude API:

```ruby
# app/models/meal_plan.rb
has_many_attached :pantry_images

validate :acceptable_pantry_images

private

def acceptable_pantry_images
  pantry_images.each do |image|
    unless image.content_type.in?(%w[image/jpeg image/png image/webp])
      errors.add(:pantry_images, "must be a JPEG, PNG, or WebP image")
    end

    if image.byte_size > 3.75.megabytes
      errors.add(:pantry_images, "must be smaller than 3.75 MB")
      # Claude API enforces a ~5 MB limit per base64-encoded image. Base64 encoding
      # adds ~33% overhead, so a 3.75 MB source file encodes to ~5 MB in the payload.
      # Do NOT set this limit to 5 MB — a 5 MB source encodes to ~6.7 MB and exceeds
      # the API constraint. The limit must be applied BEFORE encoding, not after.
    end
  end
end
```

### `meals`

One record per day per meal plan.

```
id
meal_plan_id        references    not null
day_of_week         integer       0 = Sunday, 6 = Saturday
dinner              string        not null
lunch               string        not null
prep_note           string
estimated_cost      decimal       precision: 10, scale: 2
created_at
updated_at

index [:meal_plan_id, :day_of_week], unique: true
```

Add model-level validations to match:

```ruby
# app/models/meal.rb
validates :day_of_week, inclusion: { in: 0..6 }  # 0 = Sunday, 6 = Saturday — guard against malformed AI responses
validates :day_of_week, uniqueness: { scope: :meal_plan_id }
```

### `shopping_items`

Tied to a meal plan. Can be added manually without a meal.

```
id
meal_plan_id        references    not null — all items belong to a week's plan, including manually added ones
name                string        not null
quantity            string        e.g. "3 lbs", "1 dozen"
estimated_cost      decimal       precision: 10, scale: 2
checked             boolean       default false, not null
store               string        default "Aldi"
created_at
updated_at
```

### `lunch_logs`

One record per workday.

```
id
user_id             references    not null — the user who logged this entry
date                date          not null
packed              boolean       not null
saved_amount        decimal       precision: 10, scale: 2, default: 8.00, null: false
created_at
updated_at
```

### `push_subscriptions`

One record per browser subscription per user. Created when a user grants push notification permission, destroyed when they revoke it.

```
id
user_id             references    not null
endpoint            string        not null — the browser's push service URL
p256dh_key          string        not null — public encryption key
auth_key            string        not null — authentication secret
created_at
updated_at
```

### Database constraints

Model validations are your first line of defense. The database is the last. Rails validations can be bypassed via `update_column`, direct ActiveRecord calls in jobs, and the Rails console. These migration additions enforce data integrity regardless of how a record is written.

**Foreign keys** — declare explicitly in migrations so PostgreSQL enforces referential integrity at the DB level:

```ruby
# In the initial migrations or a dedicated db/migrate/..._add_foreign_keys.rb
add_foreign_key :envelope_budgets, :envelopes
add_foreign_key :expenses, :envelopes
add_foreign_key :expenses, :users
add_foreign_key :meals, :meal_plans
add_foreign_key :shopping_items, :meal_plans
add_foreign_key :lunch_logs, :users
add_foreign_key :push_subscriptions, :users
```

**CHECK constraints** — prevent negative or zero amounts from being stored, regardless of how the record is written:

```ruby
# Amounts must be positive — prevent silent sign errors from corrupting envelope balances
execute "ALTER TABLE expenses ADD CONSTRAINT expenses_amount_positive CHECK (amount > 0)"
execute "ALTER TABLE envelope_budgets ADD CONSTRAINT envelope_budgets_amount_non_negative CHECK (amount >= 0)"
execute "ALTER TABLE meals ADD CONSTRAINT meals_estimated_cost_non_negative CHECK (estimated_cost IS NULL OR estimated_cost >= 0)"
execute "ALTER TABLE shopping_items ADD CONSTRAINT shopping_items_estimated_cost_non_negative CHECK (estimated_cost IS NULL OR estimated_cost >= 0)"
execute "ALTER TABLE lunch_logs ADD CONSTRAINT lunch_logs_saved_amount_positive CHECK (saved_amount > 0)"
```

**Why `execute` instead of the ActiveRecord DSL:** Rails 7.1+ supports `add_check_constraint`, but using raw SQL keeps the constraint definition readable and portable, and is less likely to be silently dropped during schema dumps if the Rails version or adapter changes. Either approach is fine — be consistent within the codebase.

**Verify all constraints are captured in `schema.rb`:** After running migrations, confirm that `db/schema.rb` includes the foreign key and check constraint declarations. If PostgreSQL constraints are not reflected in `schema.rb`, `rails db:schema:load` (used in CI) will not recreate them and the test database will lack the DB-level guarantees.

---

## Tech stack

| Layer              | Choice                                               | Reason                                                                          |
| ------------------ | ---------------------------------------------------- | ------------------------------------------------------------------------------- |
| Framework          | Rails 8                                              | Familiar from studio booking app                                                |
| Auth               | Rails 8 auth generator                               | No gem overhead, right-sized for one household                                  |
| Frontend           | ERB, Hotwire, Stimulus                               | Same as studio app                                                              |
| Components         | ViewComponent gem                                    | Encapsulated, testable UI components — logic lives in Ruby, not templates       |
| Style composition  | `UiHelper` / `UiPresenter`                           | Centralizes Tailwind class strings — ERB templates stay free of styling clutter |
| Styles             | Tailwind CSS v4                                      | CSS variable configuration, no `tailwind.config.js`                             |
| Database           | PostgreSQL                                           | Railway native                                                                  |
| Charts             | Chartkick + Groupdate                                | Rails-native, minimal JS                                                        |
| AI                 | Claude API (`claude-sonnet-4-6`)                     | Meal plan and shopping list generation                                          |
| PWA                | Manual manifest + service worker                     | Home screen install, offline shell                                              |
| Hosting            | Railway                                              | Already in budget                                                               |
| Testing            | RSpec, Capybara, ViewComponent test helpers, WebMock | Model specs, component specs, request specs, system tests                       |
| Rate limiting      | `rack-attack` gem                                    | Brute-force login protection, Claude API cost control                           |
| Push notifications | `web-push` gem + PWA service worker                  | Expense notifications between Josh and Sally                                    |
| N+1 detection      | `bullet` gem (development only)                      | Catches inefficient queries before they reach production                        |
| Background jobs    | Solid Queue (Rails 8 default)                        | Monthly rollover, push notifications — no Redis needed                          |
| Domain             | `ramsey.thebrileys.com`                              | Custom domain configured in Railway                                             |
| CI                 | GitHub Actions                                       | Runs full RSpec suite on every push and pull request                            |

---

## Claude API integration detail

The AI meal planner makes a single API call per planning session. The system prompt is assembled server-side in a Rails service object and is never exposed to the client.

**System prompt context injected automatically:**

```
You are a meal planning assistant for a family of three: Josh, Sally, and their
daughter Kayla.

Household rules:
- Grocery envelope remaining this week: $X (injected at call time)
- Shopping strategy: Aldi first, Stop & Shop for anything Aldi does not carry
- Family size: 3 people. Plan portions accordingly.
- Leftovers: dinner portions should yield at least one packed lunch the next day
- Keep meals practical and kid-friendly where possible

Respond only with valid JSON in this exact structure, with no preamble or
markdown fences:
{
  "meals": [
    {
      "day_of_week": 0,
      "dinner": "string",
      "lunch": "string",
      "prep_note": "string",
      "estimated_cost": 0.00
    }
  ],
  "shopping_items": [
    {
      "name": "string",
      "quantity": "string",
      "estimated_cost": 0.00,
      "store": "Aldi"
    }
  ]
}
```

**User message:** Sally's plain-language input, passed verbatim.

**Rails service object:** `MealPlannerService` — assembles the prompt, calls the API with `max_tokens: 2000` and a `timeout: 30` (seconds) on the HTTP client, parses and validates the JSON response, and returns a preview object. Does not write to the database. The controller saves to the database only after Sally confirms the preview. If the API call times out or returns malformed JSON, the service raises a descriptive error that the controller renders as a user-facing message ("The meal planner took too long to respond. Try again.").

**Image encoding — S3 download is a blocking operation:** When pantry images are attached, `MealPlannerService` must download each blob from S3 before base64-encoding it. Use `blob.download` (Active Storage's streaming download method) for each attached image:

```ruby
# Inside MealPlannerService#encode_images
meal_plan.pantry_images.map do |image|
  {
    type: "image",
    source: {
      type: "base64",
      media_type: image.content_type,
      data: Base64.strict_encode64(image.blob.download)
    }
  }
end
```

This means a single plan-generation request blocks a Puma thread for the sum of: S3 download time per image + Claude API response time. With the 30-second HTTP timeout and multiple images, a thread can be held for 30–60 seconds. For a two-user household app this is acceptable, but Puma's thread pool size should be set high enough (at least 5) to avoid all threads being consumed by simultaneous meal plan requests. Set `WEB_CONCURRENCY` and `RAILS_MAX_THREADS` in Railway's environment variables accordingly.

---

## Design system

Derived from the official style guide (Figma: mood tracking app, node 151-423). All values are exact — sourced directly from the Color, Typography, Spacing, and Radius sheets.

The aesthetic is calm and approachable: a soft lavender gradient page background, white card surfaces, blue/indigo brand accents, and a fully rounded component language. Nothing clinical or sterile.

---

### Color tokens

All hex values are exact from the style guide color sheet.

```css
:root {
  /* Neutral scale */
  --neutral-900: #21214d; /* Deep navy — primary text, headings */
  --neutral-600: #57577b; /* Mid slate — secondary text */
  --neutral-300: #9393b7; /* Muted — disabled, placeholder */
  --neutral-200: #cbcdd0; /* Light — borders, dividers */
  --neutral-0: #ffffff; /* White — card surfaces */

  /* Blue scale — primary brand */
  --blue-700: #2a4cd5; /* Deep blue — active states, strong CTA */
  --blue-600: #4865db; /* Primary blue — buttons, links, accents */
  --blue-200: #c7d3f7; /* Light blue — tinted card backgrounds */
  --blue-100: #e0e6fa; /* Pale blue — subtle hover states */

  /* Semantic */
  --red-700: #e60013; /* Error, destructive actions */
  --red-300: #ff9b99; /* Soft red — warning backgrounds */
  --indigo-200: #b8b1ff; /* Indigo tint — accent, tag backgrounds */
  --blue-300: #89caff; /* Sky blue — chart bar, info */
  --green-300: #89e780; /* Sage green — success, under-budget */
  --amber-300: #ffc97c; /* Warm amber — caution, current week */

  /* Background gradient */
  --bg-gradient: linear-gradient(180deg, #f5f5ff 72.99%, #e0e0ff 100%);
}
```

---

### Tailwind v4 CSS configuration (`app/assets/stylesheets/application.css`)

Tailwind v4 uses CSS custom properties defined in your stylesheet instead of a `tailwind.config.js` file. All design tokens live here. Standard Tailwind spacing utilities (`p-4`, `gap-6`, etc.) are used throughout — no custom spacing scale needed.

```css
@import 'tailwindcss';

@theme {
  /* Font */
  --font-sans: 'Reddit Sans', ui-sans-serif, system-ui, sans-serif;

  /* Colors — neutral scale */
  --color-hs-navy: #21214d;
  --color-hs-slate: #57577b;
  --color-hs-muted: #9393b7;
  --color-hs-border: #cbcdd0;
  --color-hs-white: #ffffff;

  /* Colors — blue / brand */
  --color-hs-primary: #4865db;
  --color-hs-primary-dark: #2a4cd5;
  --color-hs-blue-light: #c7d3f7;
  --color-hs-blue-pale: #e0e6fa;

  /* Colors — semantic */
  --color-hs-red: #e60013;
  --color-hs-red-soft: #ff9b99;
  --color-hs-indigo: #b8b1ff;
  --color-hs-sky: #89caff;
  --color-hs-green: #89e780;
  --color-hs-amber: #ffc97c;

  /* Border radius — from Figma radius scale */
  --radius-sm: 4px;
  --radius-md: 10px;
  --radius-lg: 16px;
  --radius-xl: 20px;
  --radius-full: 999px;

  /* Shadows */
  --shadow-card: 0 2px 16px rgba(33, 33, 77, 0.08);
}

/* Page background — gradient from Figma style guide */
body {
  background: linear-gradient(180deg, #f5f5ff 72.99%, #e0e0ff 100%);
  min-height: 100vh;
  font-family: var(--font-sans);
  color: var(--color-hs-navy);
}

/* Honor the OS-level "Reduce Motion" accessibility setting (WCAG 2.3.3).
   Transition and animation utilities are used throughout — this ensures users
   with vestibular disorders or motion sensitivity are not affected. */
@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    transition-duration: 0.01ms !important;
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
  }
}
```

In ERB templates, reference these tokens via standard Tailwind color utilities — Tailwind v4 automatically generates utility classes from `@theme` variables:

```erb
<%# These utility classes are generated automatically from @theme tokens above %>
class="bg-hs-primary text-hs-white border-hs-border text-hs-navy"
```

---

### Typography

**Font family:** Reddit Sans (Google Fonts). All weights and styles are from this single family.

| Preset   | Size               | Line height        | Weight                    | Usage                      |
| -------- | ------------------ | ------------------ | ------------------------- | -------------------------- |
| Preset 1 | 52px / 46px mobile | 140% / 120%        | Bold                      | Page hero headings         |
| Preset 2 | 40px / 32px mobile | 120%               | Bold                      | Section headings           |
| Preset 3 | 32px / 28px mobile | 140% / 130%        | Bold                      | Card headings              |
| Preset 4 | 24px               | 140%               | SemiBold / Regular        | Sub-headings               |
| Preset 5 | 20px               | 140%               | SemiBold                  | Labels, nav items          |
| Preset 6 | 18px               | 120% / 130% / 140% | Medium / Italic / Regular | Body text                  |
| Preset 7 | 15px               | 140%               | Regular                   | Secondary body, metadata   |
| Preset 8 | 13px               | 100%               | SemiBold                  | Tags, badges, small labels |
| Preset 9 | 12px               | 110%               | Regular                   | Fine print, timestamps     |

Letter spacing: −2px on Preset 1, −0.3px on Presets 2–3, 0px on Presets 4–9.

**Tailwind utility mapping:**

- Page heading: `text-[52px] font-bold leading-[140%] tracking-[-0.02em] text-hs-navy`
- Card heading: `text-[32px] font-bold leading-[140%] tracking-[-0.3px] text-hs-navy`
- Accent label (e.g. "Hello, Sally!"): `text-xl font-semibold text-hs-primary`
- Body: `text-lg font-medium leading-[120%] text-hs-navy`
- Secondary: `text-[15px] text-hs-slate leading-[140%]`
- Tag/badge: `text-[13px] font-semibold`

**Tailwind v4 @theme type scale:** The arbitrary size values above (`text-[52px]`, `text-[32px]`, `text-[15px]`, `text-[13px]`) should be registered as named tokens in the `@theme` block so they're available as utilities (`text-preset-1` etc.) and can be changed in one place. Add to `application.css`:

```css
@theme {
  /* ... existing tokens ... */

  /* Type scale */
  --text-preset-1: 52px; /* Page hero */
  --text-preset-3: 32px; /* Card heading */
  --text-preset-7: 15px; /* Secondary body */
  --text-preset-8: 13px; /* Tags, badges */
}
```

Then use `text-preset-1`, `text-preset-3`, etc. in templates instead of arbitrary brackets. This keeps the design system truly single-source-of-truth — changing a type size in `@theme` updates every usage automatically.

---

### Component architecture

**Two layers work together:**

- **ViewComponent** handles structure, logic, and conditional rendering. Each component is a Ruby class with an associated template. Components own their data, their state, and what they render for each user role.
- **`UiHelper` / `UiPresenter`** handles style composition. All Tailwind class strings live in one Ruby object. ERB templates call `ui.card`, `ui.button(:primary)`, `ui.input(:error)` and receive a composed class string. No Tailwind clutter in templates.

**`UiPresenter` location:** Define `UiPresenter` in `app/presenters/ui_presenter.rb` as a standalone class — not nested inside `UiHelper`. A nested class creates an awkward constant lookup path (`UiHelper::UiPresenter`), breaks isolated unit testing (the constant is inaccessible without loading the helper), and is non-standard in Rails. The `UiHelper#ui` method instantiates it the same way either way: `@ui ||= UiPresenter.new`.

---

**`UiHelper` — style composition**

```ruby
# app/helpers/ui_helper.rb
module UiHelper
  def ui
    @ui ||= UiPresenter.new
  end
end
```

```ruby
# app/presenters/ui_presenter.rb
class UiPresenter
  def card
    "bg-white rounded-xl shadow-card p-6"
  end

  def card_header
    "flex items-center justify-between mb-3"
  end

  def stat_card
    "bg-hs-blue-pale rounded-2xl p-5 border border-hs-border"
  end

  def button(variant = :primary, extra: nil)
    # focus-visible: shows the ring only during keyboard navigation, not on mouse clicks.
    # focus: would show the ring on every click — visually noisy and not needed for mouse users.
    # WCAG 2.4.7 requires a visible focus indicator; focus-visible satisfies this for keyboard users.
    base = "font-semibold text-lg rounded-full px-10 py-3 transition-colors " \
           "focus:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 disabled:cursor-not-allowed"
    variants = {
      primary:   "bg-hs-primary text-white hover:bg-hs-primary-dark " \
                 "focus-visible:ring-hs-primary disabled:bg-hs-muted disabled:text-white",
      secondary: "bg-transparent text-hs-primary border border-hs-primary " \
                 "hover:bg-hs-blue-pale focus-visible:ring-hs-primary disabled:opacity-40",
    }
    [base, variants[variant], extra].compact.join(" ")
  end

  def input(state = :default)
    base = "w-full rounded-[10px] border px-4 py-3 text-lg " \
           "text-hs-navy placeholder:text-hs-muted focus:outline-none focus-visible:ring-2"
    states = {
      default: "border-hs-border focus-visible:border-hs-primary focus-visible:ring-hs-primary",
      error:   "border-hs-red focus-visible:border-hs-red focus-visible:ring-hs-red",
    }
    [base, states[state]].join(" ")
  end

  def label(variant = :default)
    {
      default:   "text-[13px] font-semibold text-hs-slate",
      secondary: "text-[15px] text-hs-slate leading-[140%]",
      accent:    "text-xl font-semibold text-hs-primary",
    }[variant]
  end

  def stat_value(variant: :default)
    base = "text-[32px] font-bold leading-[140%]"
    [base, { default: "text-hs-navy", danger: "text-hs-red" }[variant]].join(" ")
  end

  def link(variant = :default)
    {
      default: "text-hs-primary font-semibold underline-offset-2 hover:underline",
      subtle:  "text-[13px] text-hs-slate hover:text-hs-primary transition-colors",
    }[variant]
  end

  def warning_banner
    "bg-hs-red-soft/30 border border-hs-red-soft rounded-xl " \
    "px-4 py-3 text-[15px] text-hs-navy flex items-center gap-2"
  end

  def tag_label
    "flex items-center gap-2 px-3 py-2 rounded-[10px] border " \
    "border-hs-border cursor-pointer has-[:checked]:border-hs-primary"
  end
end
```

---

**Form accessibility requirements**

These requirements apply to every form in the app — the expense log form, the envelope settings form, the meal plan chat input, and the shopping item add form.

**Label/input association:** Every `<input>`, `<textarea>`, and `<select>` must have an explicit `<label>` linked via matching `for` and `id` attributes. Implicit labels (wrapping the input inside the label tag) are not sufficient for all screen reader/browser combinations.

```erb
<%# Correct — explicit for/id association %>
<label for="expense_amount" class="<%= ui.label %>">Amount</label>
<input type="number" id="expense_amount" name="expense[amount]" class="<%= ui.input %>">

<%# Incorrect — implicit association, screen reader support varies %>
<label class="<%= ui.label %>">Amount <input type="number" ...></label>
```

When using Rails form helpers, `f.label` and `f.input` generate correct `for`/`id` pairs automatically — use them instead of raw HTML inputs.

**Error message linking:** When a field has a validation error, the error message must be linked to the input via `aria-describedby`. This tells screen readers to announce the error when the field receives focus.

```erb
<label for="expense_amount" class="<%= ui.label %>">Amount</label>
<input type="number"
       id="expense_amount"
       name="expense[amount]"
       class="<%= ui.input(:error) %>"
       aria-describedby="expense_amount_error"
       aria-invalid="true">
<p id="expense_amount_error" class="text-hs-red text-[13px] mt-1">
  Amount must be greater than 0
</p>
```

**Required fields:** Mark required inputs with `aria-required="true"`. Do not rely solely on a visual asterisk — it conveys nothing to screen readers.

```erb
<input type="number"
       id="expense_amount"
       aria-required="true"
       ...>
```

Rails' `required: true` on `f.input` renders the HTML `required` attribute, which browsers treat as `aria-required="true"` automatically. Prefer this over setting the ARIA attribute manually.

---

**`IconHelper` — inline SVG rendering**

```ruby
# app/helpers/icon_helper.rb
module IconHelper
  VALID_ICONS = %w[
    arrow-right arrow-diagonal-up arrow-diagonal-down
    sleep star quote chevron-down
    logout settings check close info
  ].freeze

  # Thread-safe cache: Concurrent::Map (from concurrent-ruby, already a Rails dependency)
  # handles concurrent reads and writes safely under Puma's multi-threaded config.
  # Plain Hash is not thread-safe for concurrent writes — two threads reading a missing
  # key simultaneously would both write, producing a data race.
  ICON_CACHE = Concurrent::Map.new

  def icon(name, classes: "w-5 h-5", decorative: true)
    raise ArgumentError, "Unknown icon: #{name}" unless VALID_ICONS.include?(name.to_s)

    svg = ICON_CACHE.compute_if_absent(name.to_s) do
      path = Rails.root.join("app/assets/images/icons/#{name}.svg")
      # Security: .html_safe marks content as trusted and bypasses Rails escaping.
      # This is safe ONLY because the files are developer-controlled assets committed
      # to the repo. If SVG files ever come from user uploads or external sources,
      # sanitize with ActionView::Base.full_sanitizer or the rails-html-sanitizer gem
      # before calling html_safe. Verify Figma SVG exports don't include <script> or
      # inline event handlers (onload, onclick, etc.) before committing icon files.
      File.read(path).html_safe
    end

    # decorative: true (default) — icon accompanies a visible text label; hide from screen readers
    # decorative: false — standalone icon button; the caller must provide aria-label on the button
    attrs = { class: classes }
    attrs[:"aria-hidden"] = "true" if decorative

    content_tag(:span, svg, **attrs)
  end
end
```

Icon inventory — export all from Figma before Phase 1:

- `arrow-right`, `arrow-diagonal-up`, `arrow-diagonal-down`
- `sleep` (Zz), `star`, `quote`, `chevron-down`
- `logout`, `settings`, `check`, `close`
- `info` — always renders in `text-hs-red`

---

All components live in `app/components/`. Templates live alongside their class file (`component_name.html.erb`).

| Component                  | File                             | Notes                                                                                                                                                                                                                                                                                                                                 |
| -------------------------- | -------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `EnvelopeCardComponent`    | `envelope_card_component.rb`     | Renders budget/spent/remaining, budget score emoji, edit link for admin only                                                                                                                                                                                                                                                          |
| `ExpenseFormComponent`     | `expense_form_component.rb`      | Three-tap log flow — envelope pre-selected when rendered from a card                                                                                                                                                                                                                                                                  |
| `ExpenseRowComponent`      | `expense_row_component.rb`       | Single row in history list — delete control shown to admin, or to either user for current month                                                                                                                                                                                                                                       |
| `MonthSelectorComponent`   | `month_selector_component.rb`    | Scrollable month nav, marks current month                                                                                                                                                                                                                                                                                             |
| `MealPlanChatComponent`    | `meal_plan_chat_component.rb`    | Text area + image upload + submit + loading state                                                                                                                                                                                                                                                                                     |
| `MealPlanPreviewComponent` | `meal_plan_preview_component.rb` | Seven-day preview grid with editable fields, confirm button                                                                                                                                                                                                                                                                           |
| `MealDayComponent`         | `meal_day_component.rb`          | Single day row — dinner, lunch, prep note, estimated cost                                                                                                                                                                                                                                                                             |
| `ShoppingListComponent`    | `shopping_list_component.rb`     | Full list with envelope balance, running total, warning banner, log button                                                                                                                                                                                                                                                            |
| `ShoppingItemComponent`    | `shopping_item_component.rb`     | Single item row — checkbox, name, quantity, estimated cost                                                                                                                                                                                                                                                                            |
| `BudgetGraphComponent`     | `budget_graph_component.rb`      | Chartkick bar graph wrapper — eight weeks, target line                                                                                                                                                                                                                                                                                |
| `LunchTrackerComponent`    | `lunch_tracker_component.rb`     | Weekly Mon–Fri grid, packed toggle, monthly stats                                                                                                                                                                                                                                                                                     |
| `LunchDayComponent`        | `lunch_day_component.rb`         | Single day toggle cell                                                                                                                                                                                                                                                                                                                |
| `EmojiComponent`           | `emoji_component.rb`             | Renders correct emoji SVG by score (1–5) and size (:small, :large). Each SVG must include `role="img"` and a `<title>` element with a text label that communicates the budget health meaning (not the image content). Labels: 1 = "Very over budget", 2 = "Over budget", 3 = "On track", 4 = "Under budget", 5 = "Well under budget". |
| `NavComponent`             | `nav_component.rb`               | Renders correct nav links based on `current_user.role`                                                                                                                                                                                                                                                                                |
| `ModalComponent`           | `modal_component.rb`             | Generic accessible modal shell. Title prop, body slot. Owns focus trap, Escape key, backdrop close, and aria attributes.                                                                                                                                                                                                              |
| `DropdownComponent`        | `dropdown_component.rb`          | Generic accessible dropdown shell. Trigger slot, menu slot. Owns aria-expanded toggle, arrow key navigation, Escape key, and outside-click close.                                                                                                                                                                                     |
| `PageHeadingComponent`     | `page_heading_component.rb`      | Greeting + date, used on dashboard                                                                                                                                                                                                                                                                                                    |

---

**`UiPresenter` additions for modal and dropdown**

Add these methods to `UiPresenter`:

```ruby
def modal_overlay
  "fixed inset-0 bg-hs-navy/40 flex items-center justify-center z-50"
end

def modal_card
  "bg-white rounded-xl shadow-card p-8 w-full max-w-md mx-4 relative"
end

def modal_close
  "absolute top-4 right-4 text-hs-slate hover:text-hs-navy transition-colors"
end

def dropdown_card
  "absolute right-0 top-full mt-2 bg-white rounded-xl shadow-card p-5 w-56 z-40"
end

def dropdown_row
  "flex items-center gap-3 py-3 text-[20px] font-semibold text-hs-navy " \
  "hover:text-hs-primary transition-colors cursor-pointer"
end
```

---

**`ModalComponent` — generic accessible modal**

A generic wrapper. Body content is passed as a slot. The consuming template is responsible for what goes inside — `ModalComponent` owns only the shell and all accessibility behavior.

```ruby
# app/components/modal_component.rb
class ModalComponent < ViewComponent::Base
  renders_one :body

  def initialize(title:, id:)
    @title = title
    @id    = id
  end
end
```

```erb
<%# app/components/modal_component.html.erb %>
<div id="<%= @id %>"
     role="dialog"
     aria-modal="true"
     aria-labelledby="<%= @id %>-title"
     data-controller="modal"
     data-action="keydown.esc->modal#close"
     class="<%= ui.modal_overlay %> hidden">

  <div data-modal-target="card"
       class="<%= ui.modal_card %>">

    <h2 id="<%= @id %>-title"
        class="text-[32px] font-bold text-hs-navy mb-6">
      <%= @title %>
    </h2>

    <%= body %>

    <button data-action="click->modal#close"
            aria-label="Close dialog"
            class="<%= ui.modal_close %>">
      <%= icon "close", classes: "w-5 h-5" %>
    </button>

  </div>
</div>
```

**`modal_controller.js` accessibility requirements:**

- On open: move focus to the first focusable element inside the card
- Tab and Shift+Tab must cycle only within the modal — focus must not escape to the page behind it
- Escape closes the modal and returns focus to the element that triggered it
- Clicking the backdrop (overlay, not the card) closes the modal
- When closed, use the `hidden` attribute — not `opacity-0` or `pointer-events-none` — so the modal is fully removed from the accessibility tree
- `role="dialog"`, `aria-modal="true"`, and `aria-labelledby` are declared in the template and must not be added again by the controller

---

**`DropdownComponent` — generic accessible dropdown**

A generic wrapper. Both the trigger and the menu content are passed as slots. The consuming template controls the button appearance and the menu items — `DropdownComponent` owns only the shell and all accessibility behavior.

```ruby
# app/components/dropdown_component.rb
class DropdownComponent < ViewComponent::Base
  renders_one :trigger
  renders_one :menu

  def initialize(id:)
    @id = id
  end
end
```

```erb
<%# app/components/dropdown_component.html.erb %>
<div class="relative" data-controller="dropdown">

  <%# The trigger slot must be a <button> element. The consuming template sets
      data-action="click->dropdown#toggle keydown.enter->dropdown#toggle
      keydown.space->dropdown#toggle" directly on the button, not on a wrapper div.
      This avoids double-fire from the button's native click bubbling into a
      parent div's Stimulus action. %>
  <%= trigger %>

  <div id="<%= @id %>-menu"
       role="menu"
       aria-orientation="vertical"
       data-dropdown-target="menu"
       data-action="keydown.esc->dropdown#close
                    keydown.tab->dropdown#close"
       class="<%= ui.dropdown_card %> hidden">
    <%= menu %>
  </div>

</div>
```

**`dropdown_controller.js` accessibility requirements:**

- The trigger button must have `aria-haspopup="menu"` — set this in the consuming template, not the controller
- `aria-expanded` must be toggled between `"true"` and `"false"` by the controller on open and close
- On open: move focus to the first `role="menuitem"` element inside the menu
- Up and Down arrow keys move focus between menu items — `role="menuitem"` must be set on each item in the consuming template
- Escape closes the menu and returns focus to the trigger
- Tab or Shift+Tab closes the menu — focus leaves the component naturally
- A `click` listener on `document` closes the menu when clicking outside the component root
- When closed, use the `hidden` attribute so the menu is fully removed from the accessibility tree

---

**Turbo focus management**

Turbo replaces DOM nodes but does not move or restore focus. Without explicit focus management, keyboard and screen reader users lose their position in the page after a Turbo interaction.

**After Turbo Frame updates (expense form submit):** When the expense form submits and the envelope card Turbo Frame refreshes, focus is left on a now-replaced DOM node. Stimulus can restore it:

```javascript
// In expense_form_controller.js — after successful submit
success() {
  // Move focus to the updated card's heading so screen reader users hear the new balance
  this.element.closest("[data-envelope-card]")
    ?.querySelector("h3")
    ?.focus()
}
```

Alternatively, add `autofocus` to a logical target inside the Turbo Frame so the browser moves focus there after the frame swaps.

**After Turbo navigation (page changes):** Turbo Drive replaces the `<body>` on navigation without a true page load, so the browser does not move focus to the top of the page as it would on a full load. Add a skip link at the top of the layout and a focus target on the main content area:

```erb
<%# app/views/layouts/application.html.erb %>
<a href="#main-content" class="sr-only focus:not-sr-only focus:absolute focus:top-2 focus:left-2 focus:z-50 focus:px-4 focus:py-2 focus:bg-hs-primary focus:text-white focus:rounded">
  Skip to main content
</a>

<main id="main-content" tabindex="-1">
  <%= yield %>
</main>
```

`tabindex="-1"` on `<main>` allows programmatic focus via `document.getElementById("main-content").focus()` without putting it in the natural tab order. This is the standard pattern for SPAs and Turbo Drive apps.

Wire the focus movement in `app/javascript/application.js` (or a dedicated `turbo_focus_controller.js`):

```javascript
// app/javascript/application.js
// After each Turbo Drive navigation, move focus to the main content region so
// keyboard and screen reader users land at the top of the new page, not stranded
// on a now-replaced element.
document.addEventListener('turbo:load', () => {
  const main = document.getElementById('main-content')
  if (main) main.focus()
})
```

This fires on both full page loads and Turbo Drive navigations. The `tabindex="-1"` on `<main>` is required for `focus()` to work — without it, calling `.focus()` on a non-interactive element is a no-op in most browsers.

---

**Example: `EnvelopeCardComponent`**

```ruby
# app/components/envelope_card_component.rb
class EnvelopeCardComponent < ViewComponent::Base
  def initialize(envelope:, budget:, spent:, current_user:)
    @envelope = envelope
    @budget   = budget
    @spent    = spent
    @current_user = current_user
  end

  def remaining   = @budget - @spent
  def over_budget? = remaining.negative?
  def admin?       = @current_user.admin?

  def budget_score
    # Return nil when no budget is set — the template renders a neutral "–" placeholder
    # instead of the "Well under budget" emoji, which would be semantically incorrect
    # for an envelope with no budget configured.
    return nil if @budget.zero?

    pct = @spent / @budget.to_f
    return 1 if pct > 1.0
    return 2 if pct > 0.9
    return 3 if pct > 0.75
    return 4 if pct > 0.5
    5
  end
end
```

```erb
<%# app/components/envelope_card_component.html.erb %>
<div class="<%= ui.stat_card %>">
  <div class="<%= ui.card_header %>">
    <h3 class="<%= ui.label(:default) %>"><%= @envelope.name %></h3>
    <% if budget_score %>
      <%= render EmojiComponent.new(score: budget_score, size: :small) %>
    <% else %>
      <span class="<%= ui.label(:secondary) %>" aria-label="No budget set">–</span>
    <% end %>
  </div>
  <%# aria-live="polite" + aria-atomic="true": when this Turbo Frame refreshes after an expense
      is logged, screen readers announce the updated balance without the user needing to move
      focus there. aria-atomic ensures the full amount is read, not just the changed characters. %>
  <p class="<%= ui.stat_value(variant: over_budget? ? :danger : :default) %>"
     aria-live="polite"
     aria-atomic="true">
    <%= number_to_currency(remaining.abs) %>
  </p>
  <p class="<%= ui.label(:secondary) %>">
    <%= over_budget? ? "over budget" : "remaining" %>
  </p>
  <% if admin? %>
    <%= link_to "Edit budget", edit_envelope_budget_path(@envelope),
          class: ui.link(:subtle) %>
  <% end %>
</div>
```

**Rendered from the dashboard:**

```erb
<%# app/views/dashboard/index.html.erb %>
<% @envelopes.each do |envelope| %>
  <%= render EnvelopeCardComponent.new(
        envelope: envelope,
        budget:   @budgets[envelope.id] || 0,
        spent:    @totals[envelope.id] || 0,
        current_user: current_user) %>
<% end %>
```

**Dashboard controller: bulk-load budgets and spend totals to avoid N+1 queries.**

The dashboard renders nine envelope cards. Calling `envelope.budget_for` and `envelope.spent_in` per card produces 18 individual queries. These are conditional `where` queries, so `includes` does not help. Pre-load both datasets in the controller and pass the results as hashes:

```ruby
# app/controllers/dashboard_controller.rb
def index
  @envelopes = Envelope.where(active: true).order(:position)

  year  = Date.current.year
  month = Date.current.month

  @budgets = EnvelopeBudget
    .where(envelope_id: @envelopes.select(:id), year: year, month: month)
    .pluck(:envelope_id, :amount)
    .to_h

  @totals = Expense
    .where(envelope_id: @envelopes.select(:id), transacted_on: Date.new(year, month).all_month)
    .group(:envelope_id)
    .sum(:amount)
end
```

This reduces 18+ queries to 3 on every dashboard load, regardless of how many envelopes exist.

---

### Chart style (Chartkick + Chart.js)

Bar colors in order: `#89E780` (green, under-budget), `#89CAFF` (sky blue, neutral), `#FFC97C` (amber, caution), `#FF9B99` (soft red, over-budget). The $175/week target line renders in `#4865DB` as a dashed annotation. All bars use `borderRadius: 8` in Chart.js options.

**WCAG 1.4.1 (Use of Color):** Color alone must not be the only way to distinguish budget health categories. Add a data label to each bar showing the dollar amount, and use a Chart.js pattern fill plugin to give each category a distinct visual texture in addition to its color. This ensures users with color vision deficiencies (deuteranopia, protanopia) can distinguish the categories.

**WCAG 1.1.1 (Non-text Content):** Chartkick renders a `<canvas>` element, which is completely opaque to screen readers. Wrap the chart in a container with a descriptive `aria-label` and render a visually-hidden data table alongside it so screen reader users can access the same information:

```erb
<div role="img" aria-label="Weekly grocery spending over the past 8 weeks against the $175 target">
  <%= bar_chart @weekly_data, ... %>
</div>

<%# Visually hidden table — same data, accessible to screen readers %>
<table class="sr-only">
  <caption>Grocery spending by week</caption>
  <thead>
    <tr><th>Week</th><th>Amount spent</th><th>Target</th></tr>
  </thead>
  <tbody>
    <% @weekly_data.each do |week, amount| %>
      <tr>
        <td><%= week %></td>
        <td><%= number_to_currency(amount) %></td>
        <td>$175.00</td>
      </tr>
    <% end %>
  </tbody>
</table>
```

Add `.sr-only` to `application.css` if not already provided by Tailwind (`class="sr-only"` is a built-in Tailwind utility).

---

### Sentiment indicators (emoji scale)

Two scales exported as SVGs from the Figma emoji component sheets. Rendered via `EmojiComponent`.

Small scale — white outline faces on `#21214D` navy circles. Used on envelope cards and transaction rows.

Large scale — five colored illustrated faces for budget health on meal plan and shopping screens:

| Score | Label             | Face color             |
| ----- | ----------------- | ---------------------- |
| 1     | Very over budget  | `#FF9B99` (red-300)    |
| 2     | Over budget       | `#B8B1FF` (indigo-200) |
| 3     | On track          | `#89CAFF` (blue-300)   |
| 4     | Under budget      | `#89E780` (green-300)  |
| 5     | Well under budget | `#FFC97C` (amber-300)  |

Export all ten emoji SVGs from Figma before Phase 3.

---

### Mobile conventions

- Minimum tap target: 44×44px on all interactive elements (`min-h-11 min-w-11`) — WCAG 2.5.5 requires both dimensions; height alone is not sufficient for icon buttons and checkboxes
- Card padding on mobile: `p-4`, not `p-6`
- Bottom-anchored primary actions — log transaction, confirm plan — so Sally's thumb reaches them in-store
- No horizontal scroll on any viewport

---

## Security

### Authentication and session hardening

- `config.force_ssl = true` in `production.rb` — all traffic over HTTPS
- Session cookies set with `http_only: true` and `secure: true` — confirmed in `config/initializers/session_store.rb`
- Session timeout: 24 hours of inactivity — financial apps should not have indefinitely persistent sessions. Implement via a `last_active_at` column on the `sessions` table (added by Rails 8 auth generator) and a `before_action` in `ApplicationController`:

  ```ruby
  # In the ApplicationController (or the auth concern the generator creates)
  before_action :check_session_expiry

  def check_session_expiry
    if Current.session&.last_active_at&.before?(24.hours.ago)
      Current.session.destroy
      redirect_to new_session_path, alert: "Your session expired. Please sign in again."
    else
      Current.session&.touch(:last_active_at)
    end
  end
  ```

  Add `last_active_at datetime` to the `sessions` migration. The `touch` call updates it on every authenticated request. After 24 hours of no requests, the next request destroys the session and redirects to login.

  **PWA redirect:** After re-authentication, return the user to their intended URL (not root) using the standard `store_location_for` / `redirect_back_or` pattern. If Sally's session expires mid-shopping, she should land back on the shopping list, not the dashboard.

- Rails 8 auth generator handles bcrypt password hashing — no custom auth logic needed

### Secrets and credentials

All secrets live in Rails encrypted credentials (`rails credentials:edit`), never in committed environment files:

```
credentials:
  claude_api_key: ...
  vapid_public_key: ...
  vapid_private_key: ...
  cron_secret: ...
```

Railway injects `DATABASE_URL` as an environment variable automatically. Do not duplicate it in Rails credentials. Reference `ENV["DATABASE_URL"]` in `config/database.yml` for the production configuration. Storing the URL in both places creates precedence confusion.

Railway injects `RAILS_MASTER_KEY` as an environment variable at runtime. `master.key` is added to `.gitignore` before the first commit — this is non-negotiable. One leaked `master.key` exposes every secret.

### Authorization and data scoping

Two layers of authorization:

**1. Route-level:** `RequireAdmin` concern blocks standard users from admin routes.

**2. Query-level:** All data queries should use scoped lookups where possible. In v1, envelopes are shared across both users (there is no `has_many :envelopes` on `User`), so envelope lookups use `Envelope.find(params[:id])` with route-level authorization controlling who can modify them. Expense queries scope through the envelope association:

```ruby
# Scoped through the envelope — prevents accessing expenses from non-existent envelopes
envelope = Envelope.find(params[:envelope_id])
envelope.expenses.find(params[:id])
```

If the app ever grows beyond two users, introduce a `Household` join model so envelopes can be scoped to `current_user.household.envelopes`.

### Strong parameters

All controller actions use strong parameters. Set `action_on_unpermitted_parameters = :raise` in `config/environments/development.rb` — any unpermitted parameter raises an exception immediately during development and testing rather than silently failing.

### Content Security Policy

Set in `config/initializers/content_security_policy.rb`:

```ruby
Rails.application.config.content_security_policy do |policy|
  policy.default_src :self
  policy.script_src  :self
  policy.style_src   :self, :unsafe_inline, "https://fonts.googleapis.com"
  # ↑ fonts.googleapis.com serves the Reddit Sans CSS stylesheet — it hits style_src, not font_src.
  #   Without this, the browser fetches the stylesheet but the CSP blocks it and the font silently fails.
  #   Audit :unsafe_inline after Phase 1 — Tailwind v4 compiles to static CSS and may not need it.
  policy.img_src     :self, :data  # add S3/storage domain here when Active Storage backend is configured (Phase 3)
  policy.connect_src :self  # Claude API is called server-side in MealPlannerService — the browser never touches api.anthropic.com directly; add wss: domain if Action Cable is added in v2
  policy.font_src    :self, "https://fonts.gstatic.com"  # Reddit Sans font files from Google Fonts CDN
  policy.object_src  :none
  policy.frame_ancestors :none
end
```

**Post-Phase 1 action:** Audit whether `:unsafe_inline` is actually required. Tailwind v4 compiles to static CSS files and does not need it. If Chartkick, Turbo, or ViewComponent inject inline `style` attributes at runtime, those are the actual dependencies to identify and address. Removing `:unsafe_inline` closes a style injection vector.

### Rate limiting (`rack-attack`)

```ruby
# config/initializers/rack_attack.rb

# Brute-force login protection
Rack::Attack.throttle("logins/ip", limit: 5, period: 60) do |req|
  req.ip if req.path == "/session" && req.post?
end

# Claude API cost protection — throttle by IP, not session
# At the Rack middleware layer, the encrypted Rails session cookie has not been
# decrypted yet, so req.session[:user_id] returns nil. IP-based throttling is
# correct and sufficient for a two-user household app.
Rack::Attack.throttle("meal_plans/ip", limit: 5, period: 3600) do |req|
  req.ip if req.path == "/meal_plans" && req.post?
end

# General API abuse protection
Rack::Attack.throttle("requests/ip", limit: 300, period: 300) do |req|
  req.ip
end
```

---

## Operational concerns

### Error tracking

Add Sentry for production error tracking before the first Railway deploy. Railway's native Sentry integration provisions a DSN automatically — no separate Sentry account needed.

```ruby
# Gemfile
gem "sentry-ruby"
gem "sentry-rails"
```

```ruby
# config/initializers/sentry.rb
Sentry.init do |config|
  config.dsn = ENV["SENTRY_DSN"]  # injected by Railway's Sentry integration
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]

  # Only capture errors in production — not in development or test
  config.enabled_environments = %w[production]

  # Scrub PII from error reports — do not send user email addresses or request bodies
  # containing financial data to a third-party service
  config.send_default_pii = false
end
```

Add `SENTRY_DSN` to Railway's environment variables (not to Rails credentials — Sentry's DSN is not a secret, and Railway's integration sets it automatically when you enable the add-on).

**What to monitor:** Any unhandled exception in production. Pay particular attention to:

- `MealPlannerService` failures — malformed JSON from the Claude API, timeouts
- `MonthlyRolloverJob` failures — the app silently runs on last month's data if rollover fails
- `NotifyPartnerJob` failures — push delivery errors should be captured, not silently swallowed

### Database backups

Railway does not enable automatic backups by default. For a financial app, add a daily backup before going live.

**Enable Railway's built-in backup schedule:** In the Railway dashboard, open the PostgreSQL service → Settings → Backups → enable daily backups with a 7-day retention window. This requires no code changes and is the lowest-friction path.

**Verify the restore path before going live:** Create a test restore from a backup snapshot before Phase 1 ships. A backup strategy that has never been tested is not a backup strategy. The restore test takes 10 minutes and confirms that Railway's backup/restore flow works for your database size and schema.

**What to protect against:**

- Accidental data deletion via Rails console or a migration gone wrong
- Railway infrastructure incident
- A bad deploy that corrupts data before you can roll back

The 7-day retention window gives you time to notice a corruption issue before all good backups age out.

---

## Performance

### Database indexes

Add these indexes in the initial migrations — they cover every query the app runs repeatedly:

```ruby
# expenses — dashboard balance calculations and history views
add_index :expenses, [:envelope_id, :transacted_on]
add_index :expenses, :user_id  # attribution queries and per-user history

# envelope_budgets — monthly budget lookups
add_index :envelope_budgets, [:envelope_id, :year, :month], unique: true

# meal_plans — weekly plan lookup (unique: one plan per Sunday)
add_index :meal_plans, :week_start, unique: true

# meals — one record per day per plan (enforced at both DB and model level)
add_index :meals, [:meal_plan_id, :day_of_week], unique: true

# lunch_logs — one entry per user per day
add_index :lunch_logs, [:user_id, :date], unique: true
add_index :lunch_logs, :date

# shopping_items — list queries and dependent: :destroy cascade
add_index :shopping_items, :meal_plan_id

# push_subscriptions — notification delivery
add_index :push_subscriptions, :user_id
add_index :push_subscriptions, :endpoint, unique: true  # one subscription record per browser endpoint
```

### N+1 query prevention

Add the `bullet` gem to the development group. It raises an alert in the development log whenever an N+1 query is detected.

```ruby
# Gemfile (development)
gem "bullet"
```

```ruby
# config/environments/development.rb
config.after_initialize do
  Bullet.enable        = true
  Bullet.alert         = true
  Bullet.rails_logger  = true
  # NOTE: Do NOT set Bullet.raise = true here. It will crash the dev server on
  # the first N+1 it encounters. raise belongs in the test environment only.
end
```

```ruby
# config/environments/test.rb
config.after_initialize do
  Bullet.enable  = true
  Bullet.raise   = true  # N+1 in tests is a hard failure — forces fixes before they reach production
end
```

The dashboard is the highest-risk screen. The `budget_for` and `spent_in` methods each run a conditional `where` query per envelope, which `includes` cannot optimize. The dashboard controller bulk-loads budgets and spend totals into hashes (see the dashboard controller code in the component architecture section) and passes the pre-computed values to each `EnvelopeCardComponent`. This reduces 18+ queries to 3.

### Envelope balance calculation

The most-read query in the app. Run at the database level, not in Ruby:

```ruby
# app/models/envelope.rb
def spent_in(year:, month:)
  expenses
    .where(transacted_on: Date.new(year, month).all_month)
    .sum(:amount)
end

def budget_for(year:, month:)
  envelope_budgets
    .find_by(year: year, month: month)
    &.amount || 0
end
```

Both methods hit indexed columns and return a single value from the database. Do not load transaction records into Ruby to sum them.

### Fragment caching

Add after the app is stable (post-Phase 2). Each `EnvelopeCardComponent` is a strong candidate — the card only changes when a transaction is logged or the budget is edited. Cache key: `[envelope, current_month_budget, current_month_spent]`.

Hotwire Turbo Frames already limit re-renders to the changed card on transaction submit. Explicit fragment caching adds a second layer for the initial dashboard load.

### Background jobs

Rails 8 ships with Solid Queue as the default ActiveJob backend — jobs stored in the database, no Redis required. The monthly rollover job and push notification delivery both use it. Do not add Redis unless a concrete performance bottleneck requires it.

### Claude API efficiency

Each meal plan generation is one API call. Keep it that way. Do not make multiple calls to "refine" a plan — the system prompt should be complete enough that one call returns a usable result. Image encoding happens server-side in `MealPlannerService` before the call, not on the client.

Set `max_tokens: 2000` on the API call. A full seven-day meal plan with a shopping list fits comfortably within this limit. Uncapped `max_tokens` risks slow responses and higher cost if the model generates unnecessary content.

---

Each phase is designed to be completable in one to two focused weekends. Phases are ordered by daily-use value — the envelope tracker ships first because it replaces paper and pen immediately, even before the meal planner exists.

---

### Phase 1 — Foundation, PWA shell, and envelope tracker

**Goal:** Replace paper and pen. Both Josh and Sally can log transactions on their phones by end of the first weekend.

**TDD order for this phase:** Write model specs for `Envelope`, `EnvelopeBudget`, and `Expense` first. Write request specs for the `RequireAdmin` concern before implementing it. Build ViewComponents after the models pass, then write component specs for the behavioral variants.

Tasks:

1. Scaffold the app: `rails new ramsey --database=postgresql --asset-pipeline=propshaft --skip-jbuilder --skip-test`
   - `--skip-test` suppresses Minitest. Without it, Rails generates Minitest stubs alongside every model and scaffold. When RSpec is then installed, both test frameworks coexist and `rails generate` continues creating Minitest fixtures that never run.
   - Tailwind CSS v4 is configured manually via the application stylesheet (see the design system section), not via `--css=tailwind`, which installs v3 with a JS config file.
   - After scaffolding, install RSpec (`bundle exec rails generate rspec:install`) and configure generators in `config/application.rb` so `rails generate` creates RSpec specs, not Minitest stubs, and skips empty helpers and asset files:
     ```ruby
     config.generators do |g|
       g.test_framework :rspec, fixture: false
       g.helper false
       g.assets false
     end
     ```
2. Run the Rails 8 auth generator, configure session
3. Add `role` integer column to `users` table, default `0` (standard). The `User` model defines `enum :role, { standard: 0, admin: 1 }, default: :standard`.
4. Seed two user records: Josh (`role: :admin`) and Sally (`role: :standard`)
5. **Write specs first:** `spec/models/envelope_spec.rb`, `spec/models/envelope_budget_spec.rb`, `spec/models/expense_spec.rb`, `spec/models/user_spec.rb`
6. Generate `Envelope`, `EnvelopeBudget`, and `Expense` models and migrations — make the model specs pass
7. **Write request specs first:** `spec/requests/envelopes_spec.rb` covering standard-user redirect behavior
8. Build the `RequireAdmin` concern and apply it to envelope management controllers — make request specs pass
9. Add PWA manifest (`manifest.json`) and a minimal service worker — home screen installable from day one
10. Seed the nine envelopes and their April 2026 `EnvelopeBudget` records with the agreed starting amounts
11. Build the envelope dashboard and `EnvelopeCardComponent` — write component specs after
12. Build the expense log form and `ExpenseFormComponent`
13. Wire Turbo Frames so the submitting user's envelope card balance updates on expense submit without a full page reload
14. **Write system specs:** `spec/system/log_expense_spec.rb` covering the full Sally login → log → balance update journey
15. Add the GitHub Actions CI workflow (`.github/workflows/ci.yml`) — confirm the full suite passes in CI before deploying
16. Deploy to Railway, configure `ramsey.thebrileys.com` as a custom domain
17. Confirm Sally can log in, log an expense, and add the app to her iPhone home screen
18. Confirm Josh sees the settings link in nav; Sally does not

**Acceptance criteria:**

- Sally logs in, logs $47.23 to groceries, and her envelope card updates to $652.77 remaining without a full page reload (Turbo Frame updates the submitting user's card)
- Josh refreshes his browser and sees $652.77 remaining — cross-user real-time sync (Turbo Streams over Action Cable) is a v2 addition; Phase 1 is last-write-wins as specified in the decisions log
- All nine envelopes are visible on one screen on a mobile viewport
- The app installs to Sally's iPhone home screen via PWA
- Josh's navigation includes a Settings link; Sally's does not
- Sally cannot reach `/settings` or any envelope management route directly
- All model specs, request specs, and the log expense system spec pass
- CI passes on the main branch

---

### Phase 2 — Monthly reset, transaction history, and envelope settings

**Goal:** Make the envelope tracker reliable month over month, and give Josh and Sally full control over envelope budgets.

**TDD order for this phase:** Write model specs for rollover logic and the `prior_month?` scope first. Write request specs for prior-month edit restrictions before implementing the controller guards.

Tasks:

1. **Write specs first:** rollover logic in `spec/models/envelope_budget_spec.rb`, `prior_month?` scope in `spec/models/expense_spec.rb`
2. Implement monthly rollover — a Railway cron job runs on the 1st of each month, uses `upsert_all` with `unique_by:` to copy last month's `EnvelopeBudget` amounts as defaults (idempotent against Railway double-fire) — make specs pass
3. **Write request specs first:** prior-month expense delete blocked for standard users, prior-month budget edit blocked for all users
4. Build the envelope settings screen — list all envelopes with this month's budget amount as an editable input field per row — make request specs pass
5. Add "Save changes" — updates only the current month's `EnvelopeBudget` records, never retroactive
6. Add "New envelope" — form for name and this month's budget amount, creates `Envelope` + `EnvelopeBudget` records
7. Add deactivate/reactivate toggle per envelope — flips `active` boolean, preserves all history
8. Build expense history view per envelope — scrollable list, date, amount, user name (via `expense.user`), note. Eager-load users to avoid N+1: `envelope.expenses.includes(:user).where(...).order(transacted_on: :desc)`
9. Add delete for mis-entered expenses with correct role and month guards
10. Add a month selector to review prior months
11. Mobile polish — tap targets, spacing, Safari compatibility

**Acceptance criteria:**

- On the 1st of a new month, all envelopes carry their prior amounts forward automatically
- Josh can change the gas envelope budget from $300 to $400 for May without affecting April's history
- A new envelope can be added with a name and budget amount in under 30 seconds
- An envelope can be deactivated — it disappears from the dashboard but its transactions still appear in the month selector history
- Both Josh and Sally can view any prior month's expenses and meal plans
- Sally cannot add, edit, or delete a prior month expense — those controls are hidden from her UI entirely
- Josh can correct a mis-entered prior month expense
- No one can edit a prior month's envelope budget amount — that field is read-only in all contexts
- A mis-entered current month expense can be deleted by either user in two taps

---

### Phase 3 — AI meal planner chat

**Goal:** Sally can describe her week in plain language and get a full meal plan and shopping list, preview it, and confirm it to the database.

**TDD order for this phase:** Write `MealPlannerService` specs with WebMock stubs before writing the service. Write model specs for `MealPlan` and `Meal` before generating them. System spec comes after the feature works in the browser.

Tasks:

1. Add the Anthropic Ruby SDK gem
2. Configure Active Storage with S3-compatible object storage (see decisions log — Railway ephemeral storage is wiped on redeploy; pantry photos must persist across deploys)
3. **Write specs first:** `spec/services/meal_planner_service_spec.rb` with WebMock stubs for valid JSON, malformed JSON, and image encoding cases
4. Build `MealPlannerService` — make specs pass
5. **Write model specs first:** `spec/models/meal_plan_spec.rb`, `spec/models/meal_spec.rb`, `spec/models/shopping_item_spec.rb`
6. Generate `MealPlan`, `Meal`, and `ShoppingItem` models and migrations — make model specs pass
7. Add `has_many_attached :pantry_images, dependent: :purge_later` to the `MealPlan` model
8. Build the chat input view, preview view, and confirm action — `MealPlansController#create` must destroy any existing unconfirmed plan for the same `week_start` before creating a new one, so Sally can retry immediately without waiting for the nightly cleanup job
9. Build the weekly meal plan view — confirmed plan, dinner and lunch per day, prep notes, week navigation
10. **Write system spec:** `spec/system/meal_plan_chat_spec.rb` covering the full generate → edit → confirm journey
11. **Update the CSP** in `config/initializers/content_security_policy.rb` to add the Tigris/S3 bucket domain to `img_src` — without this, the browser will block every pantry image after Active Storage begins serving them from S3

**Acceptance criteria:**

- Sally types a plain-language request and gets a full week of meals back
- Sally can attach pantry and freezer photos and the generated plan accounts for what's visible in them
- The preview is editable before confirming
- The `MealPlan` (draft) record is saved immediately to support Active Storage image attachment; `Meal` and `ShoppingItem` records are only written after Sally confirms — `confirmed_at` is null until then
- The grocery envelope remaining balance is visible on the preview screen
- Sally can generate a second plan for the same week immediately after discarding the first — the previous draft is destroyed automatically
- All service specs pass with WebMock — no real API calls in the test suite

---

### Phase 4 — Shopping list and envelope integration

**Goal:** Sally can use the shopping list in-store and post a grocery transaction from it in two taps.

**TDD order for this phase:** Request spec for the "Log this shop" transaction post before building the controller action. System spec after the feature works.

Tasks:

1. **Write request spec first:** `PATCH /shopping_lists/:id/log` creates a grocery expense with the correct amount
2. Build the shopping list view — generated items from the meal plan plus a manual add form — make request spec pass
3. Checkbox interaction via Stimulus — check an item, the running estimated total updates instantly
4. Display the groceries envelope remaining balance alongside the running cart total
5. Warning banner when the estimated cart total exceeds the remaining envelope balance
6. "Log this shop" button — pre-fills a grocery transaction with the total of checked items
7. Two-tap confirm to post the transaction to the groceries envelope
8. **Write system spec:** `spec/system/shopping_list_spec.rb`

**Acceptance criteria:**

- Sally can check off items at Aldi on her phone
- She can see the groceries envelope balance while shopping
- After checkout, she posts the transaction in two taps

---

### Phase 5 — Budget vs. actual graph

**Goal:** Eight-week grocery trend visible to both Josh and Sally.

**TDD order for this phase:** Write a model or query object spec for the weekly aggregation before building it. The graph itself is spec-after.

Tasks:

1. **Write spec first:** weekly grocery spend aggregation returns correct sums grouped by week for the past eight weeks
2. Add Chartkick and Groupdate gems
3. Build the aggregation query — make spec pass
4. Render a bar graph on the groceries envelope detail page with a $175/week target line
5. Add a monthly summary stat — spend to date vs. $700

**Acceptance criteria:**

- The graph loads on the groceries envelope page
- The $175/week target line is clearly visible
- The current week updates after a new transaction is logged
- The aggregation spec passes with correct weekly grouping

---

### Phase 6 — Work lunch tracker

**Goal:** Josh logs packed lunches in one tap and sees savings against the work meals envelope.

**TDD order for this phase:** Write model spec for `LunchLog` monthly stats calculation before building the model.

Tasks:

1. **Write spec first:** `spec/models/lunch_log_spec.rb` — monthly stats: days packed, estimated savings, remaining work meals balance
2. Generate `LunchLog` model and migration — make spec pass
3. Build the weekly grid view — Monday through Friday, packed toggle per day
4. Calculate and display monthly stats
5. Default saved amount per packed lunch: $8
6. **Scope `LunchLogsController` to `current_user`** — all queries use `current_user.lunch_logs` so users cannot read or modify each other's records. This is not admin-restricted (either user can use the tracker), but records must be user-scoped. Add a `spec/requests/lunch_logs_spec.rb` that confirms a user cannot toggle or read another user's log entries.

**Acceptance criteria:**

- Josh logs a packed lunch in one tap
- Monthly savings total is visible on the same screen
- The work meals envelope remaining balance is accurate
- `LunchLog` model spec passes for monthly stats calculation

---

### Phase 7 — Push notifications

**Goal:** Josh receives a notification when Sally logs a grocery transaction, and Sally receives one when Josh logs a work lunch or any transaction.

Tasks:

1. Add the `web-push` gem
2. Generate a `PushSubscription` model to store each user's browser subscription endpoint and keys
3. Add a VAPID key pair to Rails credentials — `rails credentials:edit`
4. Build a `PushSubscriptionsController` — `create` (stores subscription on permission grant) and `destroy` (removes on permission revoke)
5. Add service worker push event listener to the existing PWA service worker — displays the notification with envelope name, amount, and remaining balance
6. Add a `NotifyPartnerJob` ActiveJob — fires after an `Expense` saves, sends a push to the other user's subscription endpoint. "The other user" is `User.where.not(id: expense.user_id).first` — valid for a two-user household; add a guard so the job no-ops gracefully if no partner exists (e.g., during initial setup before both accounts are seeded). The job must rescue `WebPush::ExpiredSubscription` and `WebPush::InvalidSubscription` and destroy the dead `PushSubscription` record rather than retrying — a failed endpoint does not recover on retry and will spam Solid Queue's dead-letter queue. Write specs (with WebMock) covering: successful delivery, expired endpoint (record destroyed), and no partner user (no-op).
7. Build the permission prompt UI — shown once after first login, uses the `UiPresenter` modal pattern
8. Test on actual iPhone Safari, not only desktop Chrome

**Notification payload:**

```json
{
  "title": "Ramsey",
  "body": "Sally logged an expense of $47.23 to Groceries. $652.77 remaining.",
  "icon": "/icons/icon-192.png"
}
```

**Acceptance criteria:**

- After granting permission, Josh receives a push notification within five seconds of Sally logging a grocery transaction
- The notification shows the envelope name, amount, and remaining balance
- Notification works when the app is closed on iOS Safari (PWA installed to home screen)
- Users can revoke notification permission via browser settings and the app handles the failed delivery gracefully without raising an error

---

## Testing strategy

### Testing approach

**TDD (spec first) for:**

- All model business logic — write the spec, make it pass, refactor
- All service objects — define expected inputs and outputs before writing the service
- All request specs — define authorization expectations before writing controller logic

These are pure Ruby with clear contracts. Writing the spec first forces edge case thinking before bugs can exist. What happens when `monthly_budget` is zero? When there are no transactions yet? When the rollover job runs for an envelope that didn't exist last month? TDD surfaces these questions at the right time.

**Spec-after for:**

- ViewComponent templates — build the component, verify in the browser, then write behavioral specs covering meaningful state variants (admin vs. standard, over-budget vs. under-budget, empty states)
- System tests — write after the feature is working, as regression coverage rather than design drivers

ERB and Hotwire interactions are difficult to drive from tests before the UI exists. The spec-after approach here still produces meaningful test coverage — it just doesn't pretend that writing assertions about HTML structure before rendering anything is useful design work.

---

### Setup

```ruby
# Gemfile (test group)
gem "rspec-rails"
gem "capybara"
gem "selenium-webdriver"
gem "webmock"
gem "database_cleaner-active_record"
gem "factory_bot_rails"
gem "shoulda-matchers"
```

**Why these choices:**

- `selenium-webdriver` is required for Capybara's `selenium_chrome_headless` driver. System tests will not run without it.
- `database_cleaner-active_record` with truncation strategy is required for system tests. Capybara runs the browser in a separate thread, so Rails' default transactional test cleanup does not apply. Without it, test data leaks between system specs.
- `webmock` stubs HTTP requests directly. VCR (previously listed) records and replays real HTTP cassettes, which conflicts with the plan's approach of never making real Claude API calls in tests. Use WebMock alone.

**Factories:** Define factories alongside model specs. At minimum, create `spec/factories/` with factories for `user`, `envelope`, `envelope_budget`, `expense`, `meal_plan`, `meal`, `shopping_item`, and `lunch_log`.

---

### Model specs

Fast, no database where possible. Cover all business logic in isolation.

```
spec/models/
  envelope_spec.rb          # active scope, associations
  envelope_budget_spec.rb   # uniqueness validation, budget_for helper
  expense_spec.rb           # prior_month? scope, user_id presence
  meal_plan_spec.rb         # confirmed?, week_start always a Sunday, Sunday validator
  lunch_log_spec.rb         # saved_amount default, monthly stats
  user_spec.rb              # role enum validation, admin? predicate, User.admin scope
```

Key cases to cover:

- `Envelope#budget_for(year:, month:)` returns correct `EnvelopeBudget` amount
- `Envelope#spent_in(year:, month:)` sums expenses correctly
- `Expense` scopes — `current_month`, `prior_month`, `for_envelope`
- `User#admin?` returns true only for role `:admin`
- `User.admin` scope returns only admin users
- `EnvelopeBudget` uniqueness constraint rejects duplicate year/month per envelope

---

### ViewComponent specs

Each component tested in isolation with `render_inline`. Cover role-based rendering and state variants.

```
spec/components/
  envelope_card_component_spec.rb
  expense_row_component_spec.rb
  nav_component_spec.rb
  modal_component_spec.rb
  dropdown_component_spec.rb
  emoji_component_spec.rb
```

Key cases to cover:

- `EnvelopeCardComponent` renders danger stat value when over budget
- `EnvelopeCardComponent` renders edit link for admin, hides it for standard user
- `ExpenseRowComponent` renders delete control for admin on prior-month expense, hides it for standard user
- `NavComponent` renders Settings link for admin, omits it for standard user
- `ModalComponent` renders `role="dialog"`, `aria-modal="true"`, and `aria-labelledby` with correct id

---

### Service specs

Mock the Claude API with WebMock. Do not make real API calls in tests.

```
spec/services/
  meal_planner_service_spec.rb
```

Key cases to cover:

- Returns a structured preview object on valid JSON response
- Raises a descriptive error on malformed JSON response
- Encodes images as base64 when present
- Injects the correct grocery envelope balance into the system prompt
- Does not write to the database

---

### Request specs

Cover authorization rules. Fast — no browser required.

```
spec/requests/
  envelopes_spec.rb         # admin-only CRUD routes reject standard users
  envelope_budgets_spec.rb  # prior-month budget amounts are read-only for all
  expenses_spec.rb          # prior-month edits blocked for standard users
  sessions_spec.rb          # login, logout, redirect behavior
  cron_spec.rb              # cron endpoint authorization — the only unauthenticated POST surface
```

Key cases to cover:

- `PATCH /envelopes/:id` returns 302 redirect to root for standard user
- `PATCH /envelope_budgets/:id` with a prior-month record returns 403 for all users
- `DELETE /expenses/:id` for a prior-month expense returns 302 for standard user
- Unauthenticated requests redirect to login
- `POST /cron/monthly_rollover` with no Authorization header → 401
- `POST /cron/monthly_rollover` with wrong token → 401
- `POST /cron/monthly_rollover` with correct token → 200 and enqueues `MonthlyRolloverJob`
- `POST /cron/purge_unconfirmed_meal_plans` with correct token → 200 and enqueues `PurgeUnconfirmedMealPlansJob`

---

### System tests

Capybara with headless Chrome. Cover critical user journeys end to end, including Hotwire interactions.

```
spec/system/
  envelope_dashboard_spec.rb
  log_expense_spec.rb
  meal_plan_chat_spec.rb
  shopping_list_spec.rb
  modal_accessibility_spec.rb
  dropdown_accessibility_spec.rb
```

Key journeys to cover:

- Sally logs an expense — the envelope card balance updates without a page reload
- Sally generates a meal plan via chat — preview renders, she edits one meal, confirms, plan saves
- Sally checks off shopping items — running total updates, "Log this shop" posts the expense
- Josh edits the groceries envelope budget — change persists, prior month is unchanged
- Modal opens, focus moves to first focusable element, Escape closes it and focus returns to trigger
- Dropdown opens, arrow keys navigate menu items, Escape closes and focus returns to trigger

---

### Continuous integration

A GitHub Actions workflow runs the full test suite on every push and pull request. This is non-negotiable for a project that treats tests as the source of truth.

```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_USER: ramsey
          POSTGRES_PASSWORD: test
          POSTGRES_DB: ramsey_test
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    env:
      DATABASE_URL: postgres://ramsey:test@localhost:5432/ramsey_test
      RAILS_ENV: test
      # RAILS_MASTER_KEY is intentionally NOT set here. The required_credentials.rb
      # initializer skips its check in the test environment (next if Rails.env.test?),
      # so the test suite boots without credentials. Do not add a RAILS_MASTER_KEY
      # secret to CI — the test suite mocks all external services and needs no real keys.
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true
      - run: bin/rails db:schema:load
      - run: bundle exec rspec
```

Add this workflow file in Phase 1 before the first Railway deploy. Every phase's acceptance criteria should include "CI passes on the main branch."

---

## Milestones

| Milestone                        | Phase   | Definition of done                                                                      |
| -------------------------------- | ------- | --------------------------------------------------------------------------------------- |
| M1: Live on Railway              | Phase 1 | Both Josh and Sally logging transactions at `ramsey.thebrileys.com`                     |
| M2: Flexible envelope management | Phase 2 | Monthly rollover confirmed, budget editing live, envelopes can be added and deactivated |
| M3: AI meal planner live         | Phase 3 | Sally generates and confirms a full week's plan via chat                                |
| M4: Shopping list integrated     | Phase 4 | One-tap transaction from shopping list after checkout                                   |
| M5: Budget graph live            | Phase 5 | Eight-week grocery trend visible                                                        |
| M6: Full app complete            | Phase 6 | All six features live, both users active                                                |
| M7: Push notifications live      | Phase 7 | Both users receive transaction notifications on iPhone                                  |

---

### Phase 8 — Gamification (conditional on 3-month usage check-in)

**Goal:** Make consistent budget tracking and meal planning feel rewarding rather than tedious.

**Trigger:** Only built if both Josh and Sally are actively using the app after three months. Evaluate on June 23, 2026 (calendar event set). If the core app hasn't changed spending behavior, fix that first.

**Data model:** No new tables required. All four mechanics derive from existing `expenses`, `envelope_budgets`, and `lunch_logs` data. The only addition is a seeded `settings` record storing the $1,076 historical grocery baseline for the savings milestone calculation.

---

**Mechanic 1 — Streaks**

Consecutive weeks under the weekly grocery target ($175), and consecutive workdays with a packed lunch. Calculated on the fly from existing data — no streak counter stored in the database, which means no stale state to manage.

```ruby
# app/models/concerns/streak_calculable.rb
def grocery_streak
  # Count consecutive completed weeks (Sun–Sat) where grocery spend < weekly budget
  # Stop at the first week that exceeds the target
end

def lunch_streak
  # Count consecutive workdays (Mon–Fri) where LunchLog.packed == true
  # Stop at the first unpacked day
end
```

Display: a flame icon and count on the dashboard. "🔥 4 weeks under budget." Resets visually when broken, but prior streak history remains queryable.

---

**Mechanic 2 — Monthly challenge**

Auto-generated on the 1st of each month by the existing rollover job. Identifies the envelope with the largest overspend from the prior month and sets a slightly more aggressive target — 10% below last month's actual spend, but no lower than the envelope's budget.

```ruby
# Added to the monthly rollover job
def generate_monthly_challenge(prior_month)
  # Bulk-load spend and budget data — do NOT call spent_in/budget_for per envelope in Ruby.
  # That pattern produces 2N queries (one sum + one select per envelope), identical to the
  # N+1 the dashboard avoids. Pre-load both datasets in two queries instead.
  active_envelope_ids = Envelope.where(active: true).pluck(:id)

  spent = Expense
    .where(envelope_id: active_envelope_ids,
           transacted_on: Date.new(prior_month.year, prior_month.month).all_month)
    .group(:envelope_id)
    .sum(:amount)

  budgets = EnvelopeBudget
    .where(envelope_id: active_envelope_ids,
           year: prior_month.year, month: prior_month.month)
    .pluck(:envelope_id, :amount)
    .to_h

  worst_id = active_envelope_ids.max_by { |id| spent[id].to_f - budgets[id].to_f }
  worst_envelope = Envelope.find(worst_id)
  # Store as a Challenge record: envelope_id, target_amount, month
end
```

One challenge per month, one envelope, one number. Visible as a progress bar on the relevant envelope card. No points, no badge — just the number and a green check when hit.

---

**Mechanic 3 — Savings milestone tracker**

Running total of actual savings versus the $1,076 historical grocery baseline. Calculated monthly: `baseline - actual_grocery_spend`. Accumulated across all months since app start.

```
Savings this month:   $312
Total saved to date:  $847
```

Displayed on the dashboard below the envelope cards. The number compounds every month and never resets — it's the most honest reflection of what the app is actually doing for the household financially.

---

**Mechanic 4 — Household score**

A single weekly number (0–100) combining performance across the food-related envelopes. Calculated Sunday night for the prior week.

```ruby
def household_score(week)
  # Guard against ZeroDivisionError when an envelope has no budget set for the week.
  # Return a neutral 0.5 (50%) contribution when the budget is zero — this avoids a
  # crash and prevents a 0-budget envelope from artificially dragging the score to 0.
  grocery_pct    = grocery_budget.zero?    ? 0.5 : [1 - (grocery_spent / grocery_budget.to_f), 0].max
  restaurant_pct = restaurant_budget.zero? ? 0.5 : [1 - (restaurant_spent / restaurant_budget.to_f), 0].max
  lunch_pct      = lunch_logs_packed / 5.0  # packed days out of 5

  # Weighted: grocery 50%, restaurant 30%, lunch 20%
  score = (grocery_pct * 50) + (restaurant_pct * 30) + (lunch_pct * 20)
  score.round
end
```

The emoji scale from the design system (1–5) maps to score ranges: 0–20 → very sad, 21–40 → sad, 41–60 → neutral, 61–80 → happy, 81–100 → very happy. Displayed as the large illustrated emoji on the dashboard with the numeric score alongside it.

---

**What is explicitly not built:**

- Badges or achievements
- Points or experience systems
- Leaderboards
- Level progression
- Any mechanic disconnected from actual money saved or spent

---

## Milestones

| Milestone                        | Phase   | Definition of done                                                                      |
| -------------------------------- | ------- | --------------------------------------------------------------------------------------- |
| M1: Live on Railway              | Phase 1 | Both Josh and Sally logging transactions at `ramsey.thebrileys.com`                     |
| M2: Flexible envelope management | Phase 2 | Monthly rollover confirmed, budget editing live, envelopes can be added and deactivated |
| M3: AI meal planner live         | Phase 3 | Sally generates and confirms a full week's plan via chat                                |
| M4: Shopping list integrated     | Phase 4 | One-tap transaction from shopping list after checkout                                   |
| M5: Budget graph live            | Phase 5 | Eight-week grocery trend visible                                                        |
| M6: Full app complete            | Phase 6 | All six features live, both users active                                                |
| M7: Push notifications live      | Phase 7 | Both users receive transaction notifications on iPhone                                  |
| M8: Gamification (conditional)   | Phase 8 | Evaluate June 23, 2026 — only build if both users are active after 3 months             |

---

## Out of scope (v1)

- Fixed expense tracking (mortgage, utilities, subscriptions)
- Savings and sinking fund tracking
- Debt snowball tracker
- Recipe storage or import
- Grocery delivery integration
- Simultaneous edit conflict resolution
- Native iOS or Android app
- Weekly circular scraping

---

## Future considerations (v2)

- Turbo Streams via Action Cable for real-time sync across two open sessions simultaneously
- Weekly Aldi circular parsing — scheduled Railway job, deals surfaced automatically in the AI chat context
- Pantry tracker — Sally logs what's on hand, the AI reads it without her having to type it each week
- Repeat meal suggestions — "make something like last Tuesday's chicken"
- Monthly budget review export — PDF summary of envelope actuals for the Ramsey review session

---

_Last updated: March 23, 2026 — revised based on fourth opinion (Rails + accessibility audit)_
