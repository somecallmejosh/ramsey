# PWA + household push notifications — 2026-11-06

Found: manifest/service worker/push job/subscription model/Stimulus controller all existed but were never wired: no SW registration, no `push_subscriptions` route, no VAPID meta tag, prompt partial never rendered, job never enqueued, SW `push` handler called `waitUntil` after an `await` (drops the notification), and no VAPID keys in credentials.

### Notifications
- [x] `ExpenseAlert` (budget-state crossing for one expense): spent through this expense vs. before it; "nearly spent" at `EnvelopeRowComponent::NEARLY_SPENT` (90%) and "over" at >100%; current month + budgeted envelopes only
- [x] Job: other members get "X logged $Y to Z" (title escalates when a threshold is crossed); the person who logged it gets only the threshold alert; payload carries `url` (category page) + `tag`
- [x] Enqueue from `ExpensesController#create` (not on Undo/restore)
- [x] Specs: job (logged / nearly / over / already over / past month / no budget / actor), request spec enqueues

### PWA wiring
- [x] Route `resources :push_subscriptions, only: [:create, :destroy]`; create is an upsert by endpoint (same device, new user = reassign)
- [x] Layout: VAPID public key (as a data attribute on the prompt), render push prompt, theme-color, OG/Twitter tags
- [x] Register SW from `application.js`; SW: offline fallback page, fixed push handler, click opens the payload URL
- [x] Prompt: show only when permission is "default"; if already granted, silently re-sync this device's subscription; iOS Safari outside the installed app gets "Add to Home Screen" guidance
- [x] Manifest: id, new icons (any + maskable), brand colours, shortcut "Log a purchase"

### Assets (new C-mark from `logos/logo.svg`)
- [x] favicon.svg (light/dark aware), favicon.ico, favicon-96, apple-touch-icon 180, manifest 192/512 any + maskable, notification badge (mono alpha)
- [x] Social share image 1200×630 in the redesign language (silver + glows, floating white card, ring, Plus Jakarta Sans)

### Verify
- [x] rspec, rubocop, brakeman; live check of manifest/SW in Chrome

### Review
- 355 examples, 0 failures (24 new: `ExpenseNotification`, job, push subscription requests, enqueue on create / not on Undo / not on failed save); rubocop clean; brakeman unchanged from main (1 pre-existing warning).
- Live (headless Chrome, 390px): SW registers at scope `/`, activates and controls the page; `clempo-v2` cache holds `/offline.html` + `/icon.svg`; all 5 manifest icons load at their declared sizes; with the server stopped, navigating shows the offline screen.
- Not verifiable here: real delivery to a phone. Needs VAPID keys in credentials (none exist yet) and HTTPS (production).
- Lunch log push is supported by the job but still not enqueued (it was never wired, and past-day logging would say "today" wrongly); left out of scope.
- Brand sources for regenerating assets: `script/brand/icons.py`, `script/brand/social-share.html`.

---

# Visual redesign from Dribbble references — 2026-11-06

Direction (shared by the 3 references): soft silver background with faint lavender/mint glow, white 24px-radius cards with diffuse shadows and no hard borders, bold geometric numbers with small cents, round icon buttons, a floating pill nav, pastel tint per category with a progress ring around its icon, black pill primary buttons and dark segmented pills.

- [x] Tokens: Plus Jakarta Sans, silver bg + fixed glow, soft shadows, pastel category palette, ink primary, indigo accent, motion curve
- [x] UiPresenter: card/panel, pill buttons (press scale), inputs, badges, floating island nav
- [x] Phosphor regular (thin line) icons instead of duotone
- [x] `CategoryLook` (icon + pastel tint per category) and `RingComponent` (SVG progress ring)
- [x] Layout: greeting header with round buttons, island nav, toast
- [x] Budget: hero balance card (double bezel + ring), category rows with ringed icons, recent list with icons, logger sheet + keypad + segmented pill
- [x] Category history, Debts, Lunch, Meals, Settings, auth pages pick up the system; hand-tune where needed
- [x] Entry fade-up (CSS, reduced-motion safe)
- [x] Verify: specs, rubocop, live 390px + desktop screenshots
- [x] Breadcrumbs (`shared/_breadcrumbs`: round back arrow + trail) on category history, debt detail/add/edit, Settings sub-pages, invites, meal plan new/show (user feedback)
- [x] Meal plan list: "This week" hero with day chips and Tonight marker; past plans as compact rows with "Use again" (user feedback)
- [x] Debt detail: hero card with ring; balance chart fixed (Chart.js had no date adapter → discrete labels, oldest first, correct starting balance)
- [x] Category rows: the row opens the category page (purchases + spending); a separate black "+" opens the logger; each row shows "$X spent" and "left of $budget" (user feedback: spending was only reachable through the logger)
- [x] Month switcher: labelled bar "‹ Oct · November 2026 / This month · Dec ›"; next month greyed (aria-disabled) instead of missing; page title on its own line (user feedback: lone arrow was unclear)

### Review
- 331 examples, 0 failures; rubocop clean. Keyboard spec now dispatches keydown events (Chrome 146 drops WebDriver keys).
- Live at 357px: Budget (hero ring, ringed category rows, logger sheet), category history, Debts, Lunch calendar, Meals, sign-in, month bar in current and past months.
- Deliberate departures from the skill's agency defaults, for low-tech users: labels kept under nav icons; section spacing stays compact (py-24 would push the core task off screen); motion limited to a short fade-up and press feedback, all off under reduced motion.

---

# All-pages audit fixes — 2026-11-06

Source: [heuristics-audit.md](heuristics-audit.md) (all pages, 4.9/10).

### Data & correctness (Sev 4)
- [x] Shopping items scoped to `current_account` (create/update/destroy) + request specs
- [x] Groceries remaining read from the current household (replace `current_groceries_remaining`)
- [x] Deleting a debt payment restores balance / paid_off_at; payment delete toast with Undo-free clear copy
- [x] Envelope + budget edit forms show errors (shared `FormErrorsComponent`)

### Shared fixes
- [x] `FormErrorsComponent` used by envelopes, envelope budgets, debts, debt payments, registrations, invitations, passwords
- [x] `disable_with` → `data-turbo-submits-with` everywhere; add to forms missing it
- [x] Nav: exact active match, `aria-current`, aria-labels match visible text
- [x] One alert banner (layout, via `ui.warning_banner`); remove per-page duplicates
- [x] Shared month switcher (arrows) for History + Lunch

### Pages
- [x] Category History: list first with heading + `friendly_day`, summary updates on delete, empty state, Undo on delete, drop weak chart
- [x] Debts: plain vocabulary + one-line explainer, APR fix, "Paying off next", payer display_name, delete-payment copy, inline errors, move up/down ordering, `bottom` contrast, members' empty state, all-paid-off state, accent token chart
- [x] Meals: Start over confirm, resume unconfirmed plan, retry keeps message, generation timeout message, shopping ✕ 44px + Undo, label `for`, required prompt, photo size check, confirm bar spacing, empty shopping list
- [x] Lunch: month arrows, bigger tap targets, failure message, no scroll hint, token colors
- [x] Auth: password reset pages rebuilt + clear errors + back link; branded reset email; password min 8 + hint + show/hide toggle; rate limits on registration/join; clearer reset-sent copy and rate-limit copy; expired invite message
- [x] Settings: "category" wording, Hide/Show, "Delete household" with type-to-confirm, budget input `ui.input`, envelope edit position/active confirm, blank budget validation, help text
- [x] Invitations: copy link button, expiry note, revoke confirm, empty state
- [x] Push prompt copy without hard-coded names
- [x] Branded 404 / 422 / 500
- [x] "category" everywhere users see "envelope"

### Verify
- [x] Specs green (except pre-existing meal_plans failures), rubocop, brakeman
- [x] Live check at 390px as member and owner

### Review
- Specs: 331 examples, 0 failures (was 231 with 9 pre-existing meal-plan failures). System suite passed 3 of 3 runs after making the documented Chrome 146 workaround global in `spec/support/capybara.rb` (JS click + value entry; Capybara still finds elements normally).
- Rubocop clean (incl. the 2 old `debt.rb` offenses). Brakeman: only the Ruby 3.2.2 EOL warning.
- Live at 390px: History delete + Undo with a real click (restores same person, date, note and timestamp), nav highlights one tab, Debts, Lunch (no sideways scroll), Meals groceries figure from this household, sign-in, password reset, Settings, Invitations.
- Migration added: `debt_payments.balance_before` (run in dev and test).
- Follow-ups for the owner: set `MAILER_FROM` and configure SMTP in production (reset emails can't send today; `production.rb` SMTP is commented out). Ruby 3.2 is past end of life.

---

# Instant expense logging redesign — 2026-11-05

Goal: logging a purchase is three taps (category → amount → Save) for every kind of user. Audit: [heuristics-audit.md](heuristics-audit.md).

- [x] Session idle timeout 24h → 60 days (`Session::IDLE_TIMEOUT`)
- [x] Tokens: trust-blue accent, sans display font, clearer semantic colors, 16px inputs
- [x] `EnvelopeRowComponent` (replaces card + pip `EmojiComponent`)
- [x] Dashboard: month summary, "Tap a category" hint, rows, Recent activity, prev/next month
- [x] Inline logger sheet + `logger` Stimulus controller (keypad, Today/Yesterday/Other, note, live "after" balance)
- [x] Turbo stream create/destroy: replace row, recent list, toast with Undo
- [x] `Expense#deletable_by?` — owner, current month, or own expense < 15 min
- [x] Layout: sign-out icon, nav labels, header only when signed in
- [x] Specs updated; full suite + rubocop green; verified in browser at 390px

### Review
- Path to log a purchase: tap category → keypad → Save (Enter works on desktop). Sheet is in-page, no fetch to open.
- Verified live at 390px and desktop: save, live "left after this", toast + Undo, inline server error, past-month read-only view.
- Specs: 231 examples. The only 9 failures (meal plan + shopping list) fail identically on untouched HEAD (Chrome 146 headless + meal planner request specs).
- Rubocop: 2 existing offenses in `app/models/debt.rb` (untouched). Brakeman: only the Ruby 3.2 EOL notice.
- Follow-ups noticed, not changed: `ApplicationHelper#current_groceries_remaining` isn't account-scoped; debts show "22.990%% APR".


---

# Clempo Rebrand (visual-only)

Visual rebrand from Ramsey → Clempo on branch `redesign`. No module rename, no DB / Kamal changes, no env-var renames. User-visible strings + visual system only.

Design sources: [docs/REDESIGN.md](../docs/REDESIGN.md), [docs/REDESIGN.css](../docs/REDESIGN.css), screen captures in [docs/images/](../docs/images/).

Token decisions (from screenshot + REDESIGN.md):
- Primary button: amethyst fill, porcelain text, ~10px radius.
- Secondary button: porcelain bg, 1px hairline, ink text, ~10px radius.
- Card: 10px radius, 1px hairline, stacked-pair soft cool shadow.
- Input / chip: 4px radius.
- Light mode only for v1; dark mode tokens present in CSS but not exercised.

---

## Phase 1 — Textual swap (Ramsey → Clempo, user-visible only)

- [ ] [app/views/layouts/application.html.erb](../app/views/layouts/application.html.erb) — `<title>`, `application-name` meta (L4, L9), header text + logo ref (L65-66)
- [ ] [app/views/pwa/manifest.json.erb](../app/views/pwa/manifest.json.erb) — `name`, `short_name`
- [ ] [app/views/pwa/service-worker.js](../app/views/pwa/service-worker.js) — `CACHE_NAME = "clempo-v1"` (force refresh)
- [ ] [app/views/sessions/new.html.erb](../app/views/sessions/new.html.erb) — marketing heading
- [ ] [app/views/registrations/new.html.erb](../app/views/registrations/new.html.erb) — marketing heading
- [ ] [app/views/invitation_acceptances/new.html.erb](../app/views/invitation_acceptances/new.html.erb) — marketing heading
- [ ] [app/controllers/registrations_controller.rb](../app/controllers/registrations_controller.rb) — welcome flash
- [ ] [app/jobs/notify_account_members_job.rb](../app/jobs/notify_account_members_job.rb) — push notification title
- [ ] [app/helpers/icon_helper.rb](../app/helpers/icon_helper.rb) — replace `ramsey2` asset ref with new monogram/logo
- [ ] [package.json](../package.json) — `"name": "clempo"`
- [ ] Leave untouched: `module Ramsey`, [config/database.yml](../config/database.yml), [config/deploy.yml](../config/deploy.yml), `RAMSEY_DATABASE_PASSWORD`.
- [ ] Grep -ri ramsey to confirm only intentional references remain (internal module/infra only).

## Phase 2 — Token system (Tailwind v4 `@theme`)

- [ ] [app/assets/stylesheets/application.css](../app/assets/stylesheets/application.css) — replace `@theme` block:
  - Import Google Fonts (Newsreader + Instrument Sans + Instrument Serif) and Phosphor duotone CSS.
  - Port REDESIGN.css tokens: porcelain/ink neutrals (h=260), amethyst accent, sage/claret/gilt semantics, spacing 4–96, radii 0/4/10/20/full, shadow-1/2, motion.
  - Rename Tailwind color utilities: `hs-navy` → `ink`, `hs-primary` → `accent` (amethyst), `hs-muted` → `fg-mute`, `hs-border` → `border`, `hs-blue-pale` → `bg-inset`, `hs-white` → `porcelain`, `hs-red` → `claret`, `hs-green` → `sage`, `hs-amber` → `gilt`, etc. Emit one mapping table at top of CSS for reference.
- [ ] Remove body gradient (`#f5f5ff → #e0e0ff`) in application.html.erb — REDESIGN is flat porcelain.
- [ ] `npm run build:css` and confirm clean build.

## Phase 3 — Fonts + icons

- [ ] [app/views/layouts/application.html.erb](../app/views/layouts/application.html.erb) L23-25 — swap Reddit Sans `<link>` for Newsreader + Instrument Sans + Instrument Serif. Preconnect to `fonts.googleapis.com` and `fonts.gstatic.com`.
- [ ] Add Phosphor duotone stylesheet link.
- [ ] [app/helpers/icon_helper.rb](../app/helpers/icon_helper.rb) — audit; migrate any custom/emoji icons to Phosphor duotone `<i class="ph-duotone ph-X">` at 20/24/32px, inheriting `currentColor` ink.
- [ ] [app/components/emoji_component.*](../app/components/) — decide: keep (limited use) or migrate to Phosphor. REDESIGN forbids emoji in product UI — likely migrate.

## Phase 4 — UiPresenter rewrite

Single file: [app/presenters/ui_presenter.rb](../app/presenters/ui_presenter.rb). Rewrite each method to use new tokens. No hardcoded hex anywhere.

- [ ] `card` — `bg-porcelain-2 rounded-[10px] border border-line shadow-[var(--shadow-1)] p-5`
- [ ] `button(:primary)` — `bg-ink text-porcelain rounded-[10px] font-ui font-medium` — or amethyst fill for CTAs (match screenshot: "Move money" = amethyst fill). Offer two primaries: `:ink` and `:accent`? Start with `:primary` = amethyst fill per screenshot, add `:ink` if needed.
- [ ] `button(:secondary)` — `bg-porcelain-2 border border-line text-ink rounded-[10px]`
- [ ] `button(:error)` — claret fill
- [ ] `input` — `rounded-[4px] border border-line bg-porcelain-2`; focus ring = 2px amethyst, 2px offset
- [ ] `label` → `meta` style — Instrument Sans 11px, uppercase, tracking +0.12em, `text-fg-mute`
- [ ] `page_heading` — Newsreader 500/32px, tracking -0.02em
- [ ] `section_heading` — Newsreader 500/24px
- [ ] `stat_value` — Newsreader 500/56px tabular-nums (the `num-hero`)
- [ ] `stat_card` — porcelain-2 bg, hairline, 10px radius
- [ ] `modal_overlay` / `modal_card` — 20px radius, backdrop blur 24px
- [ ] `nav_item` — bottom tab bar per screenshot (ink icons, uppercase micro labels)
- [ ] `divider` — 1px hairline `var(--line)`
- [ ] `tag_label` / badge — amethyst-soft pill for "ON PACE" type pills
- [ ] `link` — ink underline offset 2px, amethyst on hover

## Phase 5 — Layout chrome & components

- [ ] [app/views/layouts/application.html.erb](../app/views/layouts/application.html.erb) — header refresh: new Clempo wordmark (use [logo.svg](../app/assets/images/logos/logo.svg) via `image_tag` with `class="text-ink"` so currentColor flows), remove gradient body bg, flat porcelain bg.
- [ ] Theme-color meta + PWA manifest: `theme_color: "#1f1d29"` (ink in hex, approx) or amethyst; `background_color: "#fafaf7"` (porcelain). Will compute precise hex from oklch.
- [ ] Walk the 8 ViewComponents under [app/components/](../app/components/) visually:
  - [ ] `nav_component` — bottom bar, ink icons, micro-caps labels
  - [ ] `page_heading_component`
  - [ ] `envelope_card_component`
  - [ ] `debt_card_component`
  - [ ] `expense_row_component`
  - [ ] `expense_form_component`
  - [ ] `modal_component`
  - [ ] `emoji_component` (convert to Phosphor)
- [ ] Grep all ERB views for stale `hs-` class names and remaining gradients; fix.

## Phase 6 — Favicon / PWA icons

- [ ] Stage a standalone variant of [monogram.svg](../app/assets/images/logos/monogram.svg) with `currentColor` replaced by ink hex so it renders outside a CSS context.
- [ ] Overwrite [public/favicon.svg](../public/favicon.svg) and [public/icon.svg](../public/icon.svg) with the ink monogram.
- [ ] Regenerate PNGs (`favicon-96x96.png`, `apple-touch-icon.png`, `web-app-manifest-192x192.png`, `web-app-manifest-512x512.png`) from the monogram via `rsvg-convert` (or ImageMagick). 512 gets a porcelain background per REDESIGN flat surface rules.
- [ ] Update both `/public/` and `/public/assets/` copies.
- [ ] Update PWA manifest `theme_color` / `background_color`.

## Phase 7 — Verify

- [ ] `bin/rails server` + `npm run watch:css`, walk every screen in [docs/images/](../docs/images/) order and compare.
- [ ] Check light mode on mobile viewport (Chrome device toolbar).
- [ ] Focus ring visible on all interactive elements (tab through a form).
- [ ] `bundle exec rspec` — no regressions.
- [ ] `bin/rubocop -f github` — clean.
- [ ] `bin/brakeman --no-pager` — no new findings.
- [ ] Final `grep -ri ramsey app/ config/ public/` — only intentional internal refs remain.

## Review

All seven phases complete on branch `redesign`. Visual rebrand shipped without DB, deploy, or module-name changes.

### Delivered
- **Textual**: every user-visible "Ramsey" → "Clempo" (layout title/meta, PWA manifest, service worker cache, auth headings, welcome flash, push notification title, `package.json`). Internal `module Ramsey`, DB names, Kamal service, and `RAMSEY_DATABASE_PASSWORD` env var intentionally preserved.
- **Tokens**: Clempo token system (porcelain/ink/accent + sage/claret/gilt, oklch h=260) as canonical; legacy `hs-*` utilities kept as aliases so ~50 lines of scattered view classes render in the new palette without touching view code.
- **Fonts**: Newsreader + Instrument Sans + Instrument Serif loaded; Phosphor duotone icon stylesheet linked.
- **UiPresenter**: every method migrated to Clempo tokens. Added `:meta` label variant (11px uppercase caps) distinct from the mixed-case `:default` label.
- **Layout**: header switched to flat porcelain blurred backdrop with hairline bottom border; body gradient removed; skip-link and flash banners use sage-soft/claret-soft; push prompt redesigned with hairline + shadow-2.
- **Favicon & PWA icons**: new monogram-based [favicon.svg](../public/favicon.svg) (ink strokes + amethyst signet), regenerated `favicon-96x96.png`, `apple-touch-icon.png`, `web-app-manifest-192/512.png`, `icon.png`, and multi-size `favicon.ico`. All mirrored to `public/assets/`. PWA `theme_color` = amethyst `#7a4fb8`, `background_color` = porcelain `#fafafb`.

### Test results
- RSpec: 218 examples, 9 failures. All 9 failures verified pre-existing on the pre-rebrand tree (meal_plans/shopping_list specs depending on a broken MealPlannerService stub — unrelated).
- Rubocop: 3 offenses, all pre-existing.
- Brakeman: 1 warning (Ruby 3.2.2 EOL), pre-existing.

### Known / intentional follow-ups
1. Token rename sweep — ~50 scattered `text-hs-navy` / `bg-hs-primary` / `border-hs-border` usages render correctly via aliases; renaming to Clempo tokens is cosmetic cleanup with zero visual impact. Suggest a separate PR if desired.
2. PWA maskable icon — current source is shared with the non-maskable entry. If OS cropping cuts into the outer ring on iOS/Android install, swap to a solid-ink-disc variant.
3. Icon-level Phosphor migration — the app still renders custom SVGs from `app/assets/images/icons/` via `icon_helper.rb`. Phosphor stylesheet is loaded but not yet consumed. Convert per-component as ongoing polish.
4. EmojiComponent — [emoji_component.rb](../app/components/emoji_component.rb) is a 1–5 budget score indicator (not actual emoji). REDESIGN bans emoji but permits geometric glyphs; inspect `app/assets/images/emoji/*.svg` and redraw if faces.
5. Manual visual walkthrough — automated tests can't verify the visual rebrand. Recommended at `bin/rails server`: dashboard, expenses, debts, meal plans, lunch logs, admin settings, auth flows, focus states, and a PWA install to see the new icon.
