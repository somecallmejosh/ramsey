class MealPlannerService
  Result = Data.define(:success, :meals, :shopping_items, :error) do
    def success? = success
  end

  MODEL      = "claude-sonnet-4-6"
  MAX_TOKENS = 2000

  def initialize(message:, groceries_remaining:, images: [])
    @message             = message
    @groceries_remaining = groceries_remaining
    @images              = images
  end

  def call
    response = client.messages.create(
      model:      MODEL,
      max_tokens: MAX_TOKENS,
      system:     system_prompt,
      messages:   [{ role: "user", content: user_content }]
    )

    parse_response(response.content.first.text)
  rescue Anthropic::Errors::APITimeoutError, Anthropic::Errors::APIConnectionError,
         Net::ReadTimeout, Timeout::Error
    failure("The meal planner took too long to respond. Please try again.")
  rescue StandardError => e
    failure("The meal planner encountered an error: #{e.message}")
  end

  private

  def client
    @client ||= Anthropic::Client.new(api_key: ENV["CLAUDE_API_KEY"])
  end

  def system_prompt
    <<~PROMPT
      You are a meal planning assistant for a family of three: Josh, Sally, and their daughter Kayla.

      Household rules:
      - Grocery envelope remaining this week: $#{format("%.2f", @groceries_remaining)}
      - Shopping strategy: Aldi first, Stop & Shop for anything Aldi does not carry
      - Family size: 3 people. Plan portions accordingly.
      - Leftovers: dinner portions should yield at least one packed lunch the next day
      - Keep meals practical and kid-friendly where possible

      Respond only with valid JSON in this exact structure, with no preamble or markdown fences:
      {
        "meals": [
          {
            "day_of_week": 0,
            "dinner": "string",
            "lunch": "string",
            "prep_note": "string or null",
            "estimated_cost": 0.00
          }
        ],
        "shopping_items": [
          {
            "name": "string",
            "quantity": "string",
            "estimated_cost": 0.00,
            "store": "Aldi"
          }
        ]
      }
    PROMPT
  end

  def user_content
    return @message if @images.empty?

    # Build a multimodal content array with images first, then the text message
    content = @images.map do |img|
      {
        type:   "image",
        source: {
          type:       "base64",
          media_type: img[:content_type],
          data:       img[:data]
        }
      }
    end

    content << { type: "text", text: @message }
    content
  end

  def parse_response(text)
    data = JSON.parse(text)

    meals = Array(data["meals"]).map do |m|
      {
        day_of_week:    m["day_of_week"].to_i,
        dinner:         m["dinner"].to_s,
        lunch:          m["lunch"].to_s,
        prep_note:      m["prep_note"],
        estimated_cost: m["estimated_cost"].to_f
      }
    end

    shopping_items = Array(data["shopping_items"]).map do |i|
      {
        name:           i["name"].to_s,
        quantity:       i["quantity"].to_s,
        estimated_cost: i["estimated_cost"]&.to_f,
        store:          i["store"].presence || "Aldi"
      }
    end

    Result.new(success: true, meals: meals, shopping_items: shopping_items, error: nil)
  rescue JSON::ParserError
    failure("The meal planner returned an unexpected response. Please try again.")
  end

  def failure(message)
    Result.new(success: false, meals: [], shopping_items: [], error: message)
  end
end
