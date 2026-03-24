require "rails_helper"

RSpec.describe MealPlannerService do
  let(:groceries_remaining) { 412.50 }
  let(:user_message)        { "We have chicken breasts and frozen vegetables. Keep it simple this week." }

  let(:valid_api_response) do
    {
      "meals" => [
        { "day_of_week" => 0, "dinner" => "Roast Chicken", "lunch" => "Chicken Salad",
          "prep_note" => "Season the night before", "estimated_cost" => 14.00 },
        { "day_of_week" => 1, "dinner" => "Stir Fry", "lunch" => "Leftovers",
          "prep_note" => nil, "estimated_cost" => 8.00 },
        { "day_of_week" => 2, "dinner" => "Pasta", "lunch" => "Sandwiches",
          "prep_note" => nil, "estimated_cost" => 6.00 },
        { "day_of_week" => 3, "dinner" => "Tacos", "lunch" => "Leftovers",
          "prep_note" => nil, "estimated_cost" => 10.00 },
        { "day_of_week" => 4, "dinner" => "Soup", "lunch" => "Sandwiches",
          "prep_note" => "Freeze half", "estimated_cost" => 7.00 },
        { "day_of_week" => 5, "dinner" => "Pizza", "lunch" => "Leftovers",
          "prep_note" => nil, "estimated_cost" => 12.00 },
        { "day_of_week" => 6, "dinner" => "Burgers", "lunch" => "Salad",
          "prep_note" => nil, "estimated_cost" => 9.00 }
      ],
      "shopping_items" => [
        { "name" => "Ground beef", "quantity" => "2 lbs", "estimated_cost" => 8.00, "store" => "Aldi" },
        { "name" => "Pasta",       "quantity" => "1 box", "estimated_cost" => 1.50, "store" => "Aldi" }
      ]
    }
  end

  def stub_claude_success(body = valid_api_response)
    stub_request(:post, "https://api.anthropic.com/v1/messages")
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: {
          content: [{ type: "text", text: body.to_json }]
        }.to_json
      )
  end

  def stub_claude_malformed
    stub_request(:post, "https://api.anthropic.com/v1/messages")
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: {
          content: [{ type: "text", text: "Sorry, I cannot help with that." }]
        }.to_json
      )
  end

  def stub_claude_timeout
    stub_request(:post, "https://api.anthropic.com/v1/messages")
      .to_timeout
  end

  describe "#call" do
    context "with a valid API response" do
      before { stub_claude_success }

      it "returns a result with meals and shopping_items" do
        result = described_class.new(
          message: user_message,
          groceries_remaining: groceries_remaining
        ).call

        expect(result).to be_success
        expect(result.meals.size).to eq(7)
        expect(result.shopping_items.size).to eq(2)
      end

      it "maps meal fields correctly" do
        result = described_class.new(
          message: user_message,
          groceries_remaining: groceries_remaining
        ).call

        meal = result.meals.first
        expect(meal[:day_of_week]).to eq(0)
        expect(meal[:dinner]).to eq("Roast Chicken")
        expect(meal[:lunch]).to eq("Chicken Salad")
        expect(meal[:estimated_cost]).to eq(14.00)
      end

      it "maps shopping item fields correctly" do
        result = described_class.new(
          message: user_message,
          groceries_remaining: groceries_remaining
        ).call

        item = result.shopping_items.first
        expect(item[:name]).to eq("Ground beef")
        expect(item[:quantity]).to eq("2 lbs")
        expect(item[:store]).to eq("Aldi")
      end

      it "includes groceries_remaining in the system prompt" do
        described_class.new(
          message: user_message,
          groceries_remaining: groceries_remaining
        ).call

        expect(WebMock).to have_requested(:post, "https://api.anthropic.com/v1/messages")
          .with { |req| req.body.include?("412.50") }
      end
    end

    context "with malformed JSON from the API" do
      before { stub_claude_malformed }

      it "returns a failure result" do
        result = described_class.new(
          message: user_message,
          groceries_remaining: groceries_remaining
        ).call

        expect(result).not_to be_success
        expect(result.error).to include("meal planner")
      end
    end

    context "when the API times out" do
      before { stub_claude_timeout }

      it "returns a failure result" do
        result = described_class.new(
          message: user_message,
          groceries_remaining: groceries_remaining
        ).call

        expect(result).not_to be_success
        expect(result.error).to include("took too long")
      end
    end

    context "with base64-encoded images" do
      before { stub_claude_success }

      let(:image_data) do
        [{ content_type: "image/jpeg", data: Base64.strict_encode64("fake-image-bytes") }]
      end

      it "includes images in the API request" do
        described_class.new(
          message: user_message,
          groceries_remaining: groceries_remaining,
          images: image_data
        ).call

        expect(WebMock).to have_requested(:post, "https://api.anthropic.com/v1/messages")
          .with { |req|
            body = JSON.parse(req.body)
            body["messages"].first["content"].any? { |c| c["type"] == "image" }
          }
      end
    end
  end
end
