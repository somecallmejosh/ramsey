module IconHelper
  # Maps the app's internal icon names to Phosphor duotone icon names.
  # Unknown names pass through as raw Phosphor names (e.g. icon("arrow-up-right")).
  PHOSPHOR_MAP = {
    "arrow-right"         => "arrow-right",
    "arrow-diagonal-up"   => "arrow-up-right",
    "arrow-diagonal-down" => "arrow-down-right",
    "chevron-down"        => "caret-down",
    "close"               => "x",
    "check"               => "check",
    "info"                => "info",
    "lock"                => "lock",
    "logout"              => "sign-out",
    "settings"            => "gear",
    "sleep"               => "moon",
    "star"                => "star",
    "quote"               => "quotes",
    "budget"              => "wallet",
    "meal"                => "fork-knife",
    "lunch"               => "bowl-food",
    "debt"                => "scales"
  }.freeze

  def icon(name, classes: "w-5 h-5", decorative: true)
    ph_name = PHOSPHOR_MAP[name.to_s] || name.to_s

    size_px = classes.to_s[/\bw-(\d+)\b/, 1]&.to_i&.*(4) || 20
    residual = classes.to_s.gsub(/\b[wh]-\d+\b/, "").squeeze(" ").strip

    merged = [ "ph-duotone", "ph-#{ph_name}", "inline-flex", "items-center", "justify-center", "align-middle", residual ]
      .reject(&:blank?).join(" ")

    attrs = { class: merged, style: "font-size: #{size_px}px; line-height: 1;" }
    attrs[:"aria-hidden"] = "true" if decorative

    content_tag(:i, "", **attrs)
  end
end
