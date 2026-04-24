class EmojiComponent < ApplicationComponent
  LABELS = {
    1 => "Very over budget",
    2 => "Over budget",
    3 => "On track",
    4 => "Under budget",
    5 => "Well under budget"
  }.freeze

  def initialize(score:, size: :small)
    @score = score.to_i.clamp(0, 5)
    @size  = size
  end

  def label
    LABELS[@score] || "Unknown"
  end

  def pip_size
    @size == :large ? "w-1.5 h-1.5" : "w-1 h-1"
  end

  def gap
    @size == :large ? "gap-1.5" : "gap-1"
  end

  def pip_class(index)
    base = "#{pip_size} rounded-full"
    if index <= @score
      "#{base} bg-ink"
    else
      "#{base} bg-line"
    end
  end
end
