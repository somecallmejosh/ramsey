class UiPresenter
  # -------------------------------------------------------------------
  # Type scale — single source of truth for typography.
  # Mirrors docs/REDESIGN.css semantic tokens (--t-display, --t-h1…).
  # All text in views should resolve to one of these roles, either
  # directly via `ui.type(:key)` or through a semantic helper
  # (page_heading, section_heading, label, stat_value, etc.).
  # -------------------------------------------------------------------
  TYPE = {
    display:     "font-display font-bold text-[44px] leading-[1.05] tracking-[-0.03em] text-ink",
    heading_1:   "font-display font-bold text-[30px] leading-[1.15] tracking-[-0.025em] text-ink",
    heading_2:   "font-display font-bold text-[20px] leading-[1.25] tracking-[-0.015em] text-ink",
    heading_3:   "font-sans font-semibold text-[18px] leading-[1.3] text-ink",
    body_strong: "font-sans font-medium text-[15px] leading-[1.55] text-ink",
    body:        "font-sans text-[15px] leading-[1.55] text-ink-2",
    label:       "font-sans font-medium text-[13px] leading-[1.4] text-graphite",
    small:       "font-sans text-[13px] leading-[1.5] text-graphite",
    meta:        "font-sans font-semibold text-[11px] leading-[1.2] uppercase tracking-[0.12em] text-mute",
    num_hero:    "font-display font-bold text-[52px] leading-none tracking-[-0.03em] tabular-nums",
    num:         "font-sans font-bold text-[20px] leading-[1.2] tabular-nums text-ink"
  }.freeze

  def type(key, extra: nil)
    [ TYPE.fetch(key), extra ].compact.join(" ")
  end

  # -- Headings ---------------------------------------------------------
  # Headings emit type only; margin/spacing belongs to the view so
  # heading groups and cards can control their own rhythm.
  def page_heading(extra: nil)
    type(:heading_1, extra: extra)
  end

  def section_heading(extra: nil)
    type(:heading_2, extra: extra)
  end

  def subsection_heading(extra: nil)
    type(:heading_3, extra: extra)
  end

  def eyebrow(extra: nil)
    type(:meta, extra: extra)
  end

  # -- Labels / body text ----------------------------------------------
  def label(variant = :default)
    {
      default:   type(:label),
      secondary: type(:body),
      accent:    "font-sans font-medium text-[15px] leading-[1.55] text-accent",
      meta:      type(:meta),
      small:     type(:small)
    }[variant]
  end

  # -- Numeric display -------------------------------------------------
  def stat_value(variant: :default)
    base  = "font-display font-bold text-[32px] leading-[1.1] tracking-[-0.03em] tabular-nums"
    color = { default: "text-ink", danger: "text-claret" }[variant]
    [ base, color ].join(" ")
  end

  # -- Surfaces --------------------------------------------------------
  def card
    "panel p-5"
  end

  def card_header
    "flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between mb-4"
  end

  def stat_card
    "panel p-5"
  end

  # -- Controls --------------------------------------------------------
  def button(variant = :primary, extra: nil)
    base = "press inline-flex items-center justify-center gap-2 font-sans font-semibold text-[15px] leading-[1.2] " \
           "rounded-full px-6 py-3.5 min-h-[48px] cursor-pointer " \
           "focus:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 disabled:opacity-40 disabled:cursor-not-allowed"
    variants = {
      primary:   "bg-ink text-surface shadow-[0_8px_20px_-8px_oklch(0.2_0.02_265/0.6)] hover:bg-ink-2 focus-visible:ring-ink",
      secondary: "bg-surface text-ink shadow-[var(--shadow-1)] hover:bg-porcelain-2 focus-visible:ring-accent",
      error:     "bg-claret text-surface hover:brightness-95 focus-visible:ring-claret"
    }
    [ base, variants[variant], extra ].compact.join(" ")
  end

  def input(state = :default)
    # 16px keeps iOS Safari from zooming the page when the field is focused.
    base = "w-full rounded-[16px] border bg-porcelain-2 px-4 py-3.5 font-sans text-[16px] leading-[1.4] " \
           "text-ink placeholder:text-mute " \
           "focus:outline-none focus:bg-surface focus-visible:ring-4 " \
           "transition-[background-color,border-color,box-shadow] duration-200 ease-[cubic-bezier(0.32,0.72,0,1)]"
    states = {
      default: "border-transparent hover:border-line focus-visible:border-accent focus-visible:ring-accent-soft",
      error:   "border-claret bg-claret-soft focus-visible:border-claret focus-visible:ring-claret-soft"
    }
    [ base, states[state] ].join(" ")
  end

  # Message under a field that failed validation (give it an id and point
  # the input's aria-describedby at it).
  def field_error
    "font-sans text-[13px] leading-[1.5] text-claret mt-1"
  end

  # -- Pills / badges --------------------------------------------------
  def badge(variant = :neutral, extra: nil)
    base = "inline-flex items-center gap-1 px-2.5 py-1 rounded-full font-sans font-semibold text-[12px] leading-none"
    variants = {
      neutral: "bg-porcelain-3 text-graphite",
      accent:  "bg-lilac text-lilac-ink",
      success: "bg-mint text-mint-ink",
      danger:  "bg-claret-soft text-claret"
    }
    [ base, variants[variant], extra ].compact.join(" ")
  end

  # -- Links -----------------------------------------------------------
  def link(variant = :default)
    {
      default: "font-sans font-semibold text-[15px] text-accent hover:underline underline-offset-[3px]",
      subtle:  "font-sans text-[13px] text-mute hover:text-ink transition-colors"
    }[variant]
  end

  # -- Banners ---------------------------------------------------------
  def warning_banner
    "#{type(:body_strong)} bg-surface shadow-[var(--shadow-1)] ring-1 ring-claret/25 rounded-[20px] px-4 py-3.5 flex items-center gap-3"
  end

  def tag_label
    "flex items-center gap-2 px-3 py-2 rounded-full bg-porcelain-2 border " \
    "border-transparent cursor-pointer has-[:checked]:border-accent has-[:checked]:bg-accent-soft"
  end

  # -- Modal -----------------------------------------------------------
  def modal_overlay
    "fixed inset-0 bg-ink/35 backdrop-blur-[6px] flex items-start justify-center overflow-y-auto py-16 z-50"
  end

  def modal_card
    "bg-surface rounded-[32px] p-7 w-full max-w-md mx-4 my-auto relative animate-modal-in shadow-[var(--shadow-2)]"
  end

  def modal_close
    "absolute top-4 right-4 text-mute hover:text-ink transition-colors cursor-pointer"
  end

  # -- Dropdown --------------------------------------------------------
  def dropdown_card
    "absolute right-0 top-full mt-2 panel p-5 w-56 z-40"
  end

  def dropdown_row
    "#{type(:body_strong)} flex items-center gap-3 py-3 hover:text-accent transition-colors cursor-pointer"
  end

  # -- Navigation ------------------------------------------------------
  # Floating "island" tab bar, lifted off the bottom edge.
  def nav_bar
    "fixed inset-x-0 bottom-[max(12px,env(safe-area-inset-bottom))] z-30 flex justify-center px-4 pointer-events-none"
  end

  def nav_island
    "pointer-events-auto flex items-center gap-1 p-1.5 rounded-full bg-surface/85 backdrop-blur-xl " \
    "shadow-[0_1px_0_oklch(1_0_0)_inset,0_18px_40px_-12px_oklch(0.25_0.03_265/0.35)] ring-1 ring-ink/5"
  end

  def nav_item(active: false)
    state = active ? "bg-ink text-surface" : "text-graphite hover:bg-porcelain-2 hover:text-ink"
    "press flex flex-col items-center justify-center gap-0.5 rounded-full min-w-[68px] h-14 px-3 " \
    "font-sans font-semibold text-[11px] leading-none #{state} focus:outline-none focus-visible:ring-2 focus-visible:ring-accent"
  end

  # Round icon button (back, settings, sign out, month arrows).
  def icon_button(extra: nil)
    [ "press grid place-items-center w-11 h-11 rounded-full bg-surface text-ink shadow-[var(--shadow-1)] " \
      "hover:bg-porcelain-2 focus:outline-none focus-visible:ring-2 focus-visible:ring-accent", extra ].compact.join(" ")
  end

  # -- Misc ------------------------------------------------------------
  def divider
    "border-t border-line my-4"
  end
end
