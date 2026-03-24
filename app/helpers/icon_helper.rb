module IconHelper
  VALID_ICONS = %w[
    arrow-right arrow-diagonal-up arrow-diagonal-down
    sleep star quote chevron-down ramsey2
    logout settings check close info budget lock lunch meal
  ].freeze

  ICON_CACHE = Concurrent::Map.new

  def icon(name, classes: "w-5 h-5", decorative: true)
    raise ArgumentError, "Unknown icon: #{name}" unless VALID_ICONS.include?(name.to_s)

    svg = ICON_CACHE.compute_if_absent(name.to_s) do
      path = Rails.root.join("app/assets/images/icons/#{name}.svg")
      if path.exist?
        # Safe: files are developer-controlled assets in the repo.
        # Never pass user-provided content to html_safe.
        File.read(path).html_safe
      else
        placeholder_icon_svg(name).html_safe
      end
    end

    attrs = { class: classes }
    attrs[:"aria-hidden"] = "true" if decorative

    content_tag(:span, svg, **attrs)
  end

  private

  def placeholder_icon_svg(name)
    %(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
        <title>#{ERB::Util.html_escape(name)}</title>
        <circle cx="12" cy="12" r="10" opacity="0.3"/>
      </svg>)
  end
end
