# A circular progress ring (SVG) with optional content in the middle,
# e.g. a category icon. percent is clamped to 0..100.
class RingComponent < ApplicationComponent
  def initialize(percent:, size: 48, stroke: 4, color: "text-sage", track: "text-porcelain-3", label: nil)
    @percent = percent.to_f.clamp(0, 100)
    @size    = size
    @stroke  = stroke
    @color   = color
    @track   = track
    @label   = label
  end

  def radius = (@size - @stroke) / 2.0
end
