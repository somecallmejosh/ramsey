# The icon and pastel tint a category wears everywhere it appears.
# The icon is picked from the category's name; the tint rotates by id so
# neighbours differ and a category keeps its colour across pages.
class CategoryLook
  ICONS = [
    [ /grocer|food|market|aldi|costco/i,          "basket" ],
    [ /restaurant|dining|eat|takeout|coffee/i,    "fork-knife" ],
    [ /lunch|work meal/i,                          "bowl-food" ],
    [ /gas|fuel|car|auto|transport/i,             "gas-pump" ],
    [ /home|house|rent|mortgage/i,                "house-line" ],
    [ /util|electric|power|water|internet|phone/i, "lightning" ],
    [ /kid|child|school|baby/i,                    "baby" ],
    [ /pet|dog|cat|vet/i,                          "paw-print" ],
    [ /health|medical|doctor|pharm/i,             "first-aid" ],
    [ /gift|christmas|birthday|holiday/i,         "gift" ],
    [ /cloth|shop|amazon/i,                        "shopping-bag" ],
    [ /fun|entertain|movie|game|hobby/i,          "popcorn" ],
    [ /travel|vacation|trip/i,                     "airplane-tilt" ],
    [ /save|saving|emergency/i,                    "piggy-bank" ],
    [ /church|give|giving|charity|tithe/i,        "hand-heart" ],
    [ /personal|beauty|hair|hygien|toiletr/i,      "sparkle" ],
    [ /blow|fun money|allowance|spending|misc/i,  "smiley" ]
  ].freeze

  # Literal class strings so Tailwind can see them.
  TINTS = [
    { tile: "bg-mint",   ink: "text-mint-ink",   ring: "text-mint-ink" },
    { tile: "bg-lilac",  ink: "text-lilac-ink",  ring: "text-lilac-ink" },
    { tile: "bg-sky",    ink: "text-sky-ink",    ring: "text-sky-ink" },
    { tile: "bg-peach",  ink: "text-peach-ink",  ring: "text-peach-ink" },
    { tile: "bg-rose",   ink: "text-rose-ink",   ring: "text-rose-ink" },
    { tile: "bg-butter", ink: "text-butter-ink", ring: "text-butter-ink" }
  ].freeze

  def self.for(envelope) = new(envelope)

  def initialize(envelope)
    @envelope = envelope
  end

  def icon
    ICONS.find { |pattern, _| @envelope.name.to_s.match?(pattern) }&.last || "wallet"
  end

  def tile = tint[:tile]
  def ink  = tint[:ink]

  private

  def tint
    TINTS[@envelope.id.to_i % TINTS.size]
  end
end
