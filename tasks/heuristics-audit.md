# Heuristic audit — Clempo (all pages) — 2026-11-05

Scope: every user-facing route: sign-in / sign-up / password reset / invitations, Budget (dashboard, logger, category history), envelopes & budgets, owner Settings, Debts (list, detail, log payment, add/edit), Meals (plans, review, shopping list), Lunch, global nav/layout, error pages · Method: code (4 parallel passes, Sev-4 claims re-checked by hand) + live UI at http://localhost:3000, 390px, signed in as seed member · Stack: Rails 8, Turbo + Stimulus, ViewComponent, Tailwind v4 via `UiPresenter`, `ToastComponent`

Lens: users range from very technical to barely-online; the app must feel trustworthy. Scores are for the app *after* the dashboard redesign (the earlier dashboard-only audit is kept at the bottom).

## Scores

| #   | Heuristic                   | Score | Key evidence |
| --- | --------------------------- | ----- | ------------ |
| 1   | Visibility of system status | 5     | Dashboard/logger strong (live balance, toast). But nav shows **Budget active on every page** (`nav_component.rb:12`, seen live on Debts/Meals/Lunch); History totals don't update after delete (`expenses/destroy.turbo_stream.erb`); meal-plan spinner reloads forever with no timeout (`meal_plans/show.html.erb:4-12`); `disable_with` is dead without rails-ujs (4 forms) |
| 2   | Match with the real world   | 5     | "Envelope" on edit pages vs "category" on dashboard; "Debt Snowball", "Baby Step 2", "Target" unexplained (`debts/index.html.erb:1,4`); "22.990%% APR" (`debt_card_component.html.erb:19`, `debts/show.html.erb:33`); "Deactivate"; "Cancel account" actually deletes everything; push prompt hard-codes "Josh or Sally" (`shared/_push_prompt.html.erb:7`) |
| 3   | User control & freedom      | 4     | Deleting a debt payment never restores the balance (`debt_payment.rb:11` only `after_create`); "Start over" deletes a meal plan with no confirm (`meal_plans/show.html.erb:13,145`); "Try again" after AI failure loses message + photos; shopping item ✕ and History delete have no Undo though `ToastComponent` supports `undo_path` |
| 4   | Consistency & standards     | 4     | Month pills on History/Lunch vs arrows on dashboard; `passwords/edit.html.erb` renders unstyled browser inputs + `style="color:red"`; alerts render twice (layout banner + page banner) on auth pages; chart hex colors; "Log Payment" vs "Log payment"; default Rails `public/404.html` / `500.html` |
| 5   | Error prevention            | 4     | **Shopping items are not account-scoped** (`shopping_items_controller.rb:5,40` `MealPlan.find` / `ShoppingItem.find`) and **`current_groceries_remaining` reads any household's Groceries** (`application_helper.rb:17`); delete-household has no type-to-confirm (`admin/accounts_controller.rb:19`); no password minimum (`user.rb`); envelope "Active" checkbox hides a category with no confirm; blank budget saves as $0 (`envelopes_controller.rb:22`) |
| 6   | Recognition over recall     | 6     | Labels present almost everywhere; exceptions: password-reset fields are placeholder-only (`passwords/new:13`, `edit:14-15`); meal "Dinner/Lunch" labels not tied to inputs (`meal_plans/show.html.erb:92,99`) |
| 7   | Flexibility & efficiency    | 6     | Logger keyboard entry, "Use this week" reuse, Settings saves all budgets at once. No show-password toggle; Lunch limited to 7 months |
| 8   | Aesthetic & minimalist      | 6     | Dashboard clean. History: chart fills the first screen and the list has no heading (live); Debts card stacks name/type/badge/amount/APR/bar/min/2 actions; Meals Confirm bar at `bottom-20` covers the last card |
| 9   | Error recovery              | 4     | `envelopes/edit` and `envelope_budgets/edit` **show no errors at all** — a failed save just re-renders; password reset always says "Passwords did not match." and wipes fields (`passwords_controller.rb:25`); raw "Validation failed: …" (`envelopes_controller.rb:29`, `meal_plans_controller.rb:115`); debt forms show only the first error in a banner |
| 10  | Help & documentation        | 5     | Dashboard hint + empty states good. No explanation of the snowball method; bare one-line password-reset email (`passwords_mailer/reset.html.erb`); members with no debts get no next step; no empty state for Lunch or an empty shopping list |

Overall: 4.9/10 (dashboard alone now ~8; the rest of the app hasn't caught up)

Strengths to keep: logger sheet + Undo toast; `aria-live` toasts and skip link; 16px `ui.input`; good autocomplete on sign-in/sign-up; Settings deactivate confirm names the item and effect; expense form inline errors with `aria-invalid`.

## Findings (sorted by severity, then effort)

### [Sev 4 · S] H5 — Other households' data reachable (trust)
- Where: `app/controllers/shopping_items_controller.rb:5,40`; `app/helpers/application_helper.rb:16-25` (shown in `meal_plans/_shopping_list.html.erb:3,7,53`, sent to the AI at `meal_plans_controller.rb:37`)
- Impact: anyone signed in can add/check/delete items on another account's meal plan by ID, and the grocery budget shown in Meals can be another household's. Two accounts exist in seeds, so this is live.
- Fix: `current_account.meal_plans.find(...)`, `ShoppingItem.joins(:meal_plan).where(meal_plans: { account: current_account }).find(...)`; replace the helper with `BudgetMonth.new(current_account)` lookup of the Groceries envelope via `current_account.envelopes`. Add request specs.

### [Sev 4 · S] H3 — Removing a debt payment doesn't restore the balance
- Where: `app/models/debt_payment.rb:11`; confirm text at `debts/show.html.erb:80` admits "balance will not be automatically adjusted"
- Impact: a mistaken payment can't really be undone; the debt total stays wrong.
- Fix: `after_destroy` resets `current_balance` to the latest remaining payment's `balance_after` (or the original balance) and clears `paid_off_at`; then the toast can offer Undo.

### [Sev 4 · S] H9 — Envelope and budget edit forms fail silently
- Where: `app/views/envelopes/edit.html.erb`, `app/views/envelope_budgets/edit.html.erb`
- Impact: blank name or past-month budget re-renders with no message; owner thinks it saved.
- Fix: add the error block + `ui.input(:error)` pattern from `expense_form_component.html.erb:21-33`.

### [Sev 3 · S] H1 — "Budget" tab is highlighted on every page
- Where: `app/components/nav_component.rb:12` (`start_with?("/")`)
- Fix: exact match for `root_path` (and `/dashboard`), prefix match for others; set `aria-current="page"`.

### [Sev 3 · S] H2/H4 — "22.990%% APR"
- Where: `debt_card_component.html.erb:19`, `debts/show.html.erb:33`
- Fix: `number_to_percentage(rate, precision: 3, strip_insignificant_zeros: true)` and drop the literal `%`.

### [Sev 3 · S] H2 — Push prompt names "Josh or Sally" for every household
- Where: `app/views/shared/_push_prompt.html.erb:7`
- Fix: "Get a notification when someone in your household logs a purchase or packs lunch."

### [Sev 3 · S] H3/H5 — Meal plan "Start over" deletes with no confirm; "Try again" loses input
- Where: `meal_plans/show.html.erb:13,145,21`; orphaned ready-but-unconfirmed plans (`meal_plans_controller.rb:6,13-16,24`)
- Fix: `turbo_confirm` naming the week; have `new` redirect to an unconfirmed ready plan; prefill the retry form with the previous message.

### [Sev 3 · S] H4/H9 — Password reset pages are unstyled and misleading
- Where: `passwords/edit.html.erb` (no `ui.input`/`ui.button`, `style="color:red"`, placeholder-only), `passwords/new.html.erb:9,13`, `passwords_controller.rb:25`, `passwords_mailer/reset.html.erb`
- Impact: the one page a locked-out, least-technical user sees looks broken; every failure says "Passwords did not match."
- Fix: rebuild on `sessions/new` layout (labels, `ui.input`, `ui.button(:primary)`), real error messages, "Back to sign in" link, minimum length shown up front; a branded email with a button and "Didn't ask for this? Ignore it."

### [Sev 3 · S] H1/H4 — Errors appear twice on auth pages
- Where: layout alert (`application.html.erb:66-70`) plus page banners in `sessions/new:10-14`, `registrations/new:11-15`, `invitation_acceptances/new:9-13`, `invitations/index:9-13`
- Fix: delete the per-page banners; keep the layout one (built on `ui.warning_banner`).

### [Sev 3 · S] H5 — "Cancel account" permanently deletes the household
- Where: `admin/settings/show.html.erb:110-116`, `admin/accounts_controller.rb:19`
- Fix: label "Delete household"; confirm names the household and what goes (members, categories, all history) and suggests Export first.

### [Sev 3 · S] H1 — History summary and chart go stale after deleting a row
- Where: `expenses/destroy.turbo_stream.erb`, `expenses/index.html.erb:23-38` (no id)
- Fix: give the summary an id and replace it from a `BudgetMonth` in the stream; Undo via `ToastComponent undo_path`-style re-create, or at least show the empty state when the last row goes.

### [Sev 3 · M] H8/H4 — Category History page buries the list
- Where: `expenses/index.html.erb:12-63` (seen live: chart fills screen one, list has no heading, 7 month pills)
- Fix: reuse `dashboard/_summary` month arrows; list first under "Purchases in November" using `friendly_day`; drop or shrink the weekly chart (its target = budget ÷ 4 or 5 weeks and draws $0 lines with no budget).

### [Sev 3 · M] H2/H10 — Debts page assumes Ramsey vocabulary
- Where: `debts/index.html.erb:1,4,12,25`, `debt_card_component.html.erb:8`, `admin/debts/_form.html.erb:24-26`
- Fix: title "Debts"; one line: "Pay the smallest debt first. When it's gone, roll its payment into the next one."; "Target" → "Paying off next"; replace "Snowball order" number with move up/down.

### [Sev 3 · S] H3 — Shopping item ✕ is tiny and has no undo
- Where: `meal_plans/_shopping_list.html.erb:35-41` (16px, no padding); lunch "Log"/"Packed" pills `text-xs py-px` (`lunch_logs/_day_cell.html.erb:9,16`)
- Fix: 44px hit areas; destroy toast with `undo_path`.

### [Sev 3 · S] H9 — Raw validation text and lost input
- Where: `envelopes_controller.rb:29` (+ budget amount not re-filled, `envelopes/new.html.erb:29-36`), `meal_plans_controller.rb:115`, debt forms `full_messages.first` (`debt_payments/new.html.erb:7-12`, `admin/debts/_form.html.erb:2-7`), password reset as above
- Fix: one shared form-errors partial/component (the expense form pattern), render on 422 instead of redirect.

### [Sev 3 · S] H5 — No password minimum, no guidance
- Where: `app/models/user.rb`; `registrations/new:43`, `invitation_acceptances/new:31`
- Fix: `length: { minimum: 8 }` and hint text under the field; add a show/hide toggle (small Stimulus controller).

### [Sev 3 · M] H1 — AI meal plan can spin forever
- Where: `meal_plans/show.html.erb:4-12` (meta refresh every 3s); `disable_with: "Thinking…"` never fires (no rails-ujs)
- Fix: after ~2 min show "Still working… taking longer than usual" with a retry; switch all `disable_with` to `data-turbo-submits-with`.

### [Sev 3 · S] H2 — "Envelope" vs "category"
- Where: `envelopes/new.html.erb:2,42`, `envelopes/edit.html.erb:2`, `envelopes_controller.rb:26,41`, Settings
- Fix: "category" everywhere users see it; "Deactivate" → "Hide", "Reactivate" → "Show".

### [Sev 2 · S] Polish
- Invitations: copy button for the link, say it expires in 7 days, confirm on "Revoke" (`invitations/index.html.erb:25,39,45`).
- Branded 404/500 with a "Go to Budget" link (`public/*.html`).
- Hex/off-token colors: charts (`expenses/index.html.erb:48,60`, `debts/show.html.erb:50`), `text-green-700` (`debts/show.html.erb:39`), `bg-neutral-100` (`_day_cell.html.erb:1`); `border-border` alias in 15 places.
- Nav aria-labels ("Dashboard", "Meal Planner", "Lunch Tracker") don't match visible labels (`nav_component.html.erb`).
- Lunch: unnecessary "Scroll horizontally" hint; silent failure `head :unprocessable_content` (`lunch_logs_controller.rb:24`); no empty state.
- Debt payment author shown as email prefix (`debts/show.html.erb:70`) — use `User#display_name`.
- Envelope edit says "name & position" but has no position field (`admin/settings/show.html.erb:80`).
- Photo size "max 3.75 MB" not enforced (`meal_plans/new.html.erb:37`).
- Rate limits missing on registration and invitation acceptance.

## Plan (all done 2026-11-06, see tasks/todo.md)

- [x] Quick wins (Sev ≥3, S): data scoping (shopping items, groceries helper), debt payment `after_destroy`, edit-form errors, nav active state, APR, push prompt copy, Start over confirm, duplicate alerts, "Delete household" wording, password min
- [x] Shared-component fixes: form-errors partial (fixes H9 across envelopes/debts/auth); `turbo-submits-with` everywhere; destroy toasts with Undo for expenses/payments/shopping items; month-switcher partial shared by dashboard/History/Lunch
- [x] Larger: rebuild password reset + email; History page layout; Debts vocabulary & reordering; meal-plan timeout/retry
- [x] Polish (Sev ≤2): list above

## Not assessed

- Owner-only pages (Settings, add/edit debt, invitations) were judged from code only; the live session was a member. Check by signing in as the seed owner.
- Real-device VoiceOver/TalkBack, PWA install, push permission flow, slow-network behaviour (throttle to 3G and log a purchase).
- This is not a WCAG audit; `opacity-60` text on Debts likely fails contrast and should be measured.

---

## Earlier audit: dashboard & logging, before redesign (same day)

Scored 4.6/10. Its fixes (60-day sessions, three-tap logger sheet, Undo toast, plain status text, live balance, first-use hint, 16px inputs, sign-out icon, Recent list) are all implemented; see `tasks/todo.md`.
