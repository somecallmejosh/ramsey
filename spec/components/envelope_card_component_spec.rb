require "rails_helper"

RSpec.describe EnvelopeCardComponent, type: :component do
  let(:envelope) { create(:envelope, name: "Groceries") }
  let(:admin)    { create(:user, :admin) }
  let(:standard) { create(:user) }

  def render_card(budget:, spent:, user:, year: Date.current.year, month: Date.current.month)
    render_inline(EnvelopeCardComponent.new(
      envelope:     envelope,
      budget:       budget,
      spent:        spent,
      current_user: user,
      year:         year,
      month:        month
    ))
  end

  describe "balance display" do
    it "shows remaining balance when under budget" do
      result = render_card(budget: 700, spent: 200, user: standard)
      expect(result.text).to include("$500.00")
      expect(result.text).to include("remaining")
    end

    it "shows over budget amount and danger state when over budget" do
      result = render_card(budget: 700, spent: 750, user: standard)
      expect(result.text).to include("$50.00")
      expect(result.text).to include("over budget")
    end
  end

  describe "budget score emoji" do
    it "renders emoji when budget is set" do
      result = render_card(budget: 700, spent: 0, user: standard)
      # Score 5 = "Well under budget" — matches aria-label on EmojiComponent
      expect(result.to_html).to include("Well under budget")
    end

    it "shows no-budget placeholder when budget is zero" do
      result = render_card(budget: 0, spent: 0, user: standard)
      expect(result.to_html).to include("No budget set")
    end
  end

  describe "admin controls" do
    it "shows edit budget link for admin in current month" do
      create(:envelope_budget, envelope: envelope, year: Date.current.year, month: Date.current.month)
      result = render_card(budget: 700, spent: 0, user: admin)
      expect(result.to_html).to include("Edit budget")
    end

    it "hides edit budget link for standard user" do
      result = render_card(budget: 700, spent: 0, user: standard)
      expect(result.to_html).not_to include("Edit budget")
    end
  end

  describe "log expense link" do
    it "shows log expense link in current month" do
      result = render_card(budget: 700, spent: 0, user: standard)
      expect(result.to_html).to include("Log expense")
    end

    it "hides log expense link for prior month" do
      result = render_card(budget: 700, spent: 0, user: standard,
                           year: Date.current.last_month.year,
                           month: Date.current.last_month.month)
      expect(result.to_html).not_to include("Log expense")
    end
  end
end
