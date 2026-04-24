class UiPresenter
  # -------------------------------------------------------------------
  # Type scale — single source of truth for typography.
  # Mirrors docs/REDESIGN.css semantic tokens (--t-display, --t-h1…).
  # All text in views should resolve to one of these roles, either
  # directly via `ui.type(:key)` or through a semantic helper
  # (page_heading, section_heading, label, stat_value, etc.).
  # -------------------------------------------------------------------
  TYPE = {
    display:     "font-display font-medium text-[48px] leading-[1.08] tracking-[-0.02em] text-ink",
    heading_1:   "font-display font-medium text-[32px] leading-[1.15] tracking-[-0.02em] text-ink",
    heading_2:   "font-display font-medium text-[24px] leading-[1.2] tracking-[-0.02em] text-ink",
    heading_3:   "font-sans font-semibold text-[18px] leading-[1.3] text-ink",
    body_strong: "font-sans font-medium text-[15px] leading-[1.55] text-ink",
    body:        "font-sans text-[15px] leading-[1.55] text-ink-2",
    label:       "font-sans font-medium text-[13px] leading-[1.4] text-graphite",
    small:       "font-sans text-[13px] leading-[1.5] text-graphite",
    meta:        "font-sans font-medium text-[11px] leading-[1.2] uppercase tracking-[0.12em] text-mute",
    num_hero:    "font-display font-medium text-[56px] leading-none tracking-[-0.02em] tabular-nums",
    num:         "font-sans font-medium text-[20px] leading-[1.2] tabular-nums text-ink"
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
    base  = "font-display font-medium text-[32px] leading-[1.1] tracking-[-0.02em] tabular-nums"
    color = { default: "text-ink", danger: "text-claret" }[variant]
    [ base, color ].join(" ")
  end

  # -- Surfaces --------------------------------------------------------
  def card
    "bg-porcelain-2 rounded-[10px] border border-line shadow-[var(--shadow-1)] p-6"
  end

  def card_header
    "flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between mb-4"
  end

  def stat_card
    "bg-bg-inset rounded-[10px] p-5 border border-line"
  end

  # -- Controls --------------------------------------------------------
  def button(variant = :primary, extra: nil)
    base = "font-sans font-medium text-[15px] leading-[1.2] rounded-[10px] px-6 py-3 transition-colors " \
           "focus:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 disabled:opacity-40 disabled:cursor-not-allowed"
    variants = {
      primary:   "bg-accent text-porcelain hover:brightness-95 focus-visible:ring-accent",
      secondary: "bg-porcelain-2 text-ink border border-line hover:bg-porcelain-3 focus-visible:ring-accent",
      error:     "bg-claret text-porcelain hover:brightness-95 focus-visible:ring-claret"
    }
    [ base, variants[variant], extra ].compact.join(" ")
  end

  def input(state = :default)
    base = "w-full rounded-[6px] border bg-porcelain px-4 py-3 font-sans text-[15px] leading-[1.4] " \
           "text-ink placeholder:text-mute shadow-[inset_0_1px_0_rgba(0,0,0,0.02)] " \
           "focus:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 " \
           "transition-colors hover:border-silver"
    states = {
      default: "border-line focus-visible:border-accent focus-visible:ring-accent",
      error:   "border-claret focus-visible:border-claret focus-visible:ring-claret"
    }
    [ base, states[state] ].join(" ")
  end

  # -- Pills / badges --------------------------------------------------
  def badge(variant = :neutral, extra: nil)
    base = "#{type(:meta)} inline-flex items-center px-2 py-1 rounded-full border"
    variants = {
      neutral: "bg-bg-inset border-line text-mute",
      accent:  "bg-bg-inset border-accent/30 text-accent",
      success: "bg-sage-soft border-sage/30 text-sage",
      danger:  "bg-claret-soft border-claret/30 text-claret"
    }
    [ base, variants[variant], extra ].compact.join(" ")
  end

  # -- Links -----------------------------------------------------------
  def link(variant = :default)
    {
      default: "font-sans font-medium text-[15px] text-ink underline underline-offset-[3px] decoration-accent hover:decoration-ink",
      subtle:  "font-sans text-[13px] text-mute hover:text-ink transition-colors"
    }[variant]
  end

  # -- Banners ---------------------------------------------------------
  def warning_banner
    "#{type(:body_strong)} bg-claret-soft border border-claret/30 rounded-[10px] px-4 py-3 flex items-center gap-2"
  end

  def tag_label
    "flex items-center gap-2 px-3 py-2 rounded-[4px] border " \
    "border-line cursor-pointer has-[:checked]:border-accent has-[:checked]:bg-accent-soft"
  end

  # -- Modal -----------------------------------------------------------
  def modal_overlay
    "fixed inset-0 bg-ink/40 backdrop-blur-[24px] flex items-start justify-center overflow-y-auto py-16 z-50"
  end

  def modal_card
    "bg-porcelain-2 rounded-[20px] border border-line p-8 w-full max-w-md mx-4 my-auto relative animate-modal-in shadow-[var(--shadow-2)]"
  end

  def modal_close
    "absolute top-4 right-4 text-mute hover:text-ink transition-colors cursor-pointer"
  end

  # -- Dropdown --------------------------------------------------------
  def dropdown_card
    "absolute right-0 top-full mt-2 bg-porcelain-2 rounded-[10px] border border-line shadow-[var(--shadow-1)] p-5 w-56 z-40"
  end

  def dropdown_row
    "#{type(:body_strong)} flex items-center gap-3 py-3 hover:text-accent transition-colors cursor-pointer"
  end

  # -- Navigation ------------------------------------------------------
  def nav_bar
    "fixed bottom-0 left-0 right-0 bg-porcelain/80 backdrop-blur-[24px] border-t border-line px-4 py-2 z-30"
  end

  def nav_item(active: false)
    state = active ? "text-ink" : "text-mute hover:text-ink"
    "#{type(:meta)} #{state} flex flex-col items-center gap-1 px-3 py-2 transition-colors min-w-[44px] min-h-[44px] justify-center"
  end

  # -- Misc ------------------------------------------------------------
  def divider
    "border-t border-line my-4"
  end
end
