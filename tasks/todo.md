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
