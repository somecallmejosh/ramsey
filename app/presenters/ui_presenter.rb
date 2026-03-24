class UiPresenter
  def card
    "bg-white rounded-xl shadow-[var(--shadow-card)] p-6"
  end

  def card_header
    "flex items-center justify-between mb-3"
  end

  def stat_card
    "bg-hs-blue-pale rounded-2xl p-5 border border-hs-border"
  end

  def button(variant = :primary, extra: nil)
    base = "font-semibold text-lg rounded-full px-10 py-3 transition-colors " \
           "focus:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 disabled:cursor-not-allowed"
    variants = {
      primary:   "bg-hs-primary text-white hover:bg-hs-primary-dark " \
                 "focus-visible:ring-hs-primary disabled:bg-hs-muted disabled:text-white",
      secondary: "bg-transparent text-hs-primary border border-hs-primary " \
                 "hover:bg-hs-blue-pale focus-visible:ring-hs-primary disabled:opacity-40"
    }
    [ base, variants[variant], extra ].compact.join(" ")
  end

  def input(state = :default)
    base = "w-full rounded-[10px] border px-4 py-3 text-lg " \
           "text-hs-navy placeholder:text-hs-muted focus:outline-none focus-visible:ring-2"
    states = {
      default: "border-hs-border focus-visible:border-hs-primary focus-visible:ring-hs-primary",
      error:   "border-hs-red focus-visible:border-hs-red focus-visible:ring-hs-red"
    }
    [ base, states[state] ].join(" ")
  end

  def label(variant = :default)
    {
      default:   "text-[13px] font-semibold text-hs-slate",
      secondary: "text-[15px] text-hs-slate leading-[140%]",
      accent:    "text-xl font-semibold text-hs-primary"
    }[variant]
  end

  def stat_value(variant: :default)
    base = "text-[32px] font-bold leading-[140%]"
    [ base, { default: "text-hs-navy", danger: "text-hs-red" }[variant] ].join(" ")
  end

  def link(variant = :default)
    {
      default: "text-hs-primary font-semibold underline-offset-2 hover:underline",
      subtle:  "text-[13px] text-hs-slate hover:text-hs-primary transition-colors"
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

  def modal_overlay
    "fixed inset-0 bg-gray-900/50 backdrop-blur-sm flex items-start justify-center overflow-y-auto py-16 z-50"
  end

  def modal_card
    "bg-white rounded-2xl p-8 w-full max-w-md mx-4 my-auto relative animate-modal-in shadow-xl"
  end

  def modal_close
    "absolute top-4 right-4 text-hs-muted hover:text-hs-navy transition-colors cursor-pointer"
  end

  def dropdown_card
    "absolute right-0 top-full mt-2 bg-white rounded-xl shadow-[var(--shadow-card)] p-5 w-56 z-40"
  end

  def dropdown_row
    "flex items-center gap-3 py-3 text-[20px] font-semibold text-hs-navy " \
    "hover:text-hs-primary transition-colors cursor-pointer"
  end

  def nav_bar
    "fixed bottom-0 left-0 right-0 bg-white border-t border-hs-border px-4 py-2 z-30"
  end

  def nav_item(active: false)
    base = "flex flex-col items-center gap-1 px-3 py-2 text-[13px] font-semibold transition-colors min-w-[44px] min-h-[44px] justify-center"
    state = active ? "text-hs-primary" : "text-hs-muted hover:text-hs-slate"
    [ base, state ].join(" ")
  end

  def page_heading
    "text-[32px] font-bold leading-[140%] tracking-[-0.3px] text-hs-navy"
  end

  def section_heading
    "text-xl font-semibold text-hs-navy mb-4"
  end

  def divider
    "border-t border-hs-border my-4"
  end
end
