class EmojiComponent < ApplicationComponent
  LABELS = {
    1 => "Very over budget",
    2 => "Over budget",
    3 => "On track",
    4 => "Under budget",
    5 => "Well under budget"
  }.freeze

  def initialize(score:, size: :small)
    @score = score
    @size  = size
  end

  def label
    LABELS[@score] || "Unknown"
  end

  def svg_path
    Rails.root.join("app/assets/images/emoji/#{@size}-#{@score}.svg")
  end

  def svg_content
    return placeholder_svg unless svg_path.exist?
    File.read(svg_path).html_safe
  end

  def dimension
    @size == :large ? "w-12 h-12" : "w-8 h-8"
  end

  private

  def placeholder_svg
    <<~SVG.html_safe
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">
        <title>#{ERB::Util.html_escape(label)}</title>
        <circle cx="16" cy="16" r="14" fill="currentColor" opacity="0.3"/>
        <text x="16" y="21" text-anchor="middle" font-size="14">#{@score}</text>
      </svg>
    SVG
  end
end
