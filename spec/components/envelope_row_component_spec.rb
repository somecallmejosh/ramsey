require "rails_helper"

RSpec.describe EnvelopeRowComponent, type: :component do
  let(:account)  { create(:account) }
  let(:envelope) { create(:envelope, account: account, name: "Groceries") }
  let(:user)     { create(:user, account: account) }

  def render_row(budget:, spent:, date: Date.current)
    create(:envelope_budget, envelope: envelope, year: date.year, month: date.month, amount: budget) if budget
    create(:expense, envelope: envelope, user: user, amount: spent, transacted_on: date) if spent.positive?
    render_inline(described_class.new(envelope: envelope, budget_month: BudgetMonth.new(account, date)))
  end

  it "shows what's left in plain words" do
    result = render_row(budget: 700, spent: 200)
    expect(result.text.squish).to include("$500.00 left")
    expect(result.text.squish).to include("left of $700")
    expect(result.css("circle.text-sage")).to be_present
  end

  it "warns when nearly spent" do
    result = render_row(budget: 100, spent: 95)
    expect(result.css("circle.text-gilt")).to be_present
  end

  it "shows how far over budget" do
    result = render_row(budget: 700, spent: 750)
    expect(result.text.squish).to include("$50.00 over")
    expect(result.css(".text-claret")).to be_present
  end

  it "handles a category with no budget" do
    result = render_row(budget: nil, spent: 12)
    expect(result.text.squish).to include("$12.00 spent")
    expect(result.text).to include("No budget set")
  end

  it "opens the logger in the current month" do
    result = render_row(budget: 700, spent: 0)
    button = result.at_css("button[data-action='logger#open']")
    expect(button["data-logger-url-param"]).to eq("/envelopes/#{envelope.id}/expenses")
    expect(button["data-logger-remaining-param"]).to eq("700.0")
    expect(button["aria-label"]).to start_with("Log a purchase in Groceries")
  end

  it "shows what's been spent and links the row to the category page" do
    result = render_row(budget: 700, spent: 200)
    expect(result.text.squish).to include("$200.00 spent")
    link = result.at_css("a")
    expect(link["href"]).to eq("/envelopes/#{envelope.id}/expenses?month=#{Date.current.month}&year=#{Date.current.year}")
    expect(link["aria-label"]).to include("See purchases")
  end

  it "links to history in a past month" do
    last_month = Date.current.last_month
    result = render_row(budget: 700, spent: 10, date: last_month)
    expect(result.at_css("button[data-action='logger#open']")).to be_nil
    expect(result.at_css("a")["href"]).to include("month=#{last_month.month}")
  end
end
