# Clempo Design System

Clempo is a family budgeting app — a private, shared financial space for households. This design system defines a sophisticated, editorial visual language for the product: quieter than most fintech, more like a well-bound ledger or a private-banking quarterly than a neon-green savings app.

> **No prior brand existed.** This system was designed from first principles. Sources: none provided — everything here is original.

---

## Positioning

- **Audience:** Partners and families managing shared money — dual incomes, household budgets, kids' allowances, shared goals.
- **Voice:** A thoughtful, quietly confident advisor. Not a chirpy mascot.
- **Promise:** Money conversations become calmer, clearer, more considered.

## Core product surfaces

- **Clempo mobile app** (primary) — iOS/Android. Household dashboard, shared ledger, goals, allowances.
- _(Web companion and marketing site are out of scope for v1 of this system.)_

---

## Index

| File / Folder         | What's inside                                                     |
| --------------------- | ----------------------------------------------------------------- |
| `README.md`           | This doc — positioning, content & visual foundations, iconography |
| `colors_and_type.css` | CSS variables for color, type scale, spacing, radii, shadows      |
| `SKILL.md`            | Cross-compatible Agent Skill entry point                          |
| `assets/`             | Logo marks, monograms, brand figures                              |
| `preview/`            | Registered design-system cards (color, type, components, logo)    |
| `ui_kits/app/`        | Mobile UI kit — JSX components + interactive `index.html`         |

---

## Content fundamentals

**Tone — "the quiet advisor."** Composed, clear, and treat the reader as an adult. Never exclamatory, never infantilizing. Calm over urgent. Precision over cleverness.

**Casing.** Sentence case everywhere except the wordmark _Clempo_. No ALL-CAPS shouting. Occasional small-caps for labels is allowed (`spacing: 0.12em`, `letter-spacing` opens up slightly).

**Person.** Second-person, plural where it fits the family context. "Your household." "You and Sam have saved…" Avoid "we" as the app — the app is a surface, not a personality.

**Numerals.** Always tabular. Currency uses a thin non-breaking space between symbol and amount in display contexts: `$ 1,240`. In dense data tables, no space.

**Emoji.** Never. Not in product, not in marketing. A monogram, a serif numeral, or a small geometric glyph does the job with more dignity.

**Examples of voice:**

> ✓ "You're $240 ahead of last month."
> ✗ "Woohoo! You crushed your budget 🎉"

> ✓ "Rent posts on the 1st. Set aside $1,800 by Friday."
> ✗ "Don't forget — rent is coming!!"

> ✓ "A gentle nudge: dining out is 18% over the envelope this week."
> ✗ "⚠️ WARNING: Overspending detected!"

> ✓ "Ada's allowance, paid Sunday."
> ✗ "Allowance sent 💸"

**Microcopy patterns.**

- Confirmations are past-tense, short: "Saved." "Moved to Holiday fund."
- Errors are specific and non-blaming: "That amount is more than the envelope holds. Try a smaller transfer or top the envelope up first."
- Empty states are invitational, not cute: "Nothing here yet. Add a goal to begin."

---

## Visual foundations

### Palette

The system is built around two anchors and one jewel accent:

- **Ink** — `oklch(0.18 0.02 260)` — a midnight blue-black. Primary foreground, primary surface in dark mode, logotype.
- **Porcelain** — `oklch(0.985 0.004 260)` — a cool porcelain off-white. Primary background in light mode.
- **Amethyst** — `oklch(0.52 0.14 310)` — single jewel accent. Used like a signet: selected state, primary CTA underline, a single numeral on a hero card. Never as a flood fill for large surfaces.

Secondary greys are all on the same cool hue family (hue 260), stepping from porcelain up through `oklch(0.93 …)`, `oklch(0.82 …)`, `oklch(0.62 …)` to ink. No warm greys. No earth tones.

Semantic colors lean quiet: a muted sage for positive, a dusty claret for negative, a soft gilded ochre for warning — each desaturated to sit alongside amethyst without competing.

### Typography

- **Display** — **Newsreader** (Google Fonts). Editorial serif with high contrast and an open terminal. Used at ≥28px for screen titles, goal names, quoted balances, and hero numerals.
- **UI** — **Instrument Sans** (Google Fonts). Clean humanist grotesque. Workhorse for labels, body, buttons, navigation.
- **Italic accents** — **Instrument Serif Italic** (Google Fonts). Used sparingly for a single italicized word in a headline, or a signature line.

Tabular figures always on for monetary values. Line height opens up generously (1.5 for body, 1.15 for display). Letter-spacing tightens for display (`-0.02em`) and opens for small-caps labels (`+0.12em`).

### Spacing & rhythm

A 4px base with a musical scale: `4, 8, 12, 16, 24, 32, 48, 64, 96`. Vertical rhythm on mobile tends to 24px between major regions, 12px between paired elements. White space is a first-class element, not a consequence.

### Backgrounds

- **Porcelain flat.** The default. Utterly flat — no gradients, no textures.
- **Ink flat.** For dark mode and the occasional full-bleed "statement" screen (month close, annual summary).
- **Never.** No blurred photos, no gradient meshes, no hand-drawn squiggles, no abstract fintech blobs. The surface stays quiet so the data can speak.

A single permitted texture: an extremely subtle noise at 2% opacity on ink surfaces, to break up banding on OLED displays. Optional.

### Motion

- **Easing:** `cubic-bezier(0.22, 0.61, 0.36, 1)` — a gentle out-quart. Never spring, never bounce.
- **Duration:** 180ms for state changes, 240ms for view transitions, 400ms for content entrances (staggered 40ms per item in a list).
- **Fades dominate.** Almost everything fades and drifts 4–8px. No rotations, no scale-in from zero.
- **Financial values** ease from old→new with a brief monospace crossfade — no odometer, no number-spinning theatrics.

### States

- **Hover (pointer devices):** foreground darkens by ~6% lightness in oklch; no color shifts. Cards lift via shadow, not scale.
- **Press:** a subtle inset tint — the surface darkens 4% and a 1px inner ring of ink appears.
- **Focus:** a 2px amethyst ring offset by 2px. Always visible, never suppressed.
- **Disabled:** 40% opacity. No greying-out — we keep the hue.

### Borders, radii & shadows

- **Hairlines** at 1px, color `var(--line)` — a near-invisible cool grey. Preferred over shadows for separation.
- **Radii:** `0` (data tables, full-bleed), `4` (chips, inputs), `10` (cards, sheets), `20` (modals, bottom sheets), `9999` (pills, avatars).
- **Shadows:** one system only — a stacked pair of soft shadows with cool undertone:
  ```
  0 1px 2px oklch(0.18 0.02 260 / 0.04),
  0 8px 24px oklch(0.18 0.02 260 / 0.06)
  ```
  Never saturated shadows. Never drop-shadows with blur > 32px.

Cards: 10px radius, 1px hairline border, the shadow system above. No coloured borders, no left-accent stripes.

### Transparency & blur

Used only on bottom sheets and the app bar (in scroll). `backdrop-filter: blur(24px)` over a 70% ink or porcelain layer. Never on cards or content.

### Imagery

- **Monochrome or duotone.** Photos (when used for onboarding illustrations) are converted to ink-on-porcelain duotone. No color photography in-app.
- **Mood:** still life, domestic objects, architectural details — never stock "smiling family." The app avoids faces entirely.
- **Grain:** a very mild fine grain (2–3% opacity) on any photographic material, to match the noise treatment on ink surfaces.

### Layout rules

- **Container widths:** mobile 100% with 20px gutters; the app is not designed for web.
- **Fixed elements:** status bar, app bar (with scroll-aware blur), and tab bar. Every other element scrolls.
- **Hero numerals** are allowed to break the grid — a balance figure at 72px can extend into the gutters by 4px to feel monumental.

---

## Iconography

Clempo uses **Phosphor Icons** at **duotone** weight (light fill, regular stroke), rendered in ink. Reasoning: Phosphor's geometric-humanist balance matches Instrument Sans; duotone gives us quiet hierarchy without color.

- **Source:** `@phosphor-icons/web` via CDN `https://unpkg.com/@phosphor-icons/web@2.1.1/src/duotone/style.css`.
- **Default size:** 20px in UI, 24px in empty states, 32px in section headers.
- **Color:** inherited from `currentColor` — always ink, never amethyst. Amethyst is reserved for typographic emphasis, not icons.
- **No emoji.** Ever.
- **No unicode-glyph iconography.** Exception: `·` (middle dot) as a separator in metadata lines, and `—` (em dash) in editorial copy.
- **Custom marks:** the Clempo monogram "C" is the only bespoke glyph; see `assets/logo.svg`.

> **Substitution note:** Phosphor is the chosen system, not a placeholder — but if a specific bespoke icon is needed (e.g. a household crest), it should be drawn to match Phosphor's duotone weight and 1.5px stroke on a 24px grid.
