require "rails_helper"

RSpec.describe ExpenseNotification do
  let(:account)  { create(:account) }
  let(:josh)     { create(:user, account: account, email_address: "josh@example.com") }
  let(:envelope) { create(:envelope, account: account, name: "Groceries") }
  let(:today)    { Date.current }

  before do
    create(:envelope_budget, envelope: envelope, year: today.year, month: today.month, amount: 100)
  end

  def log(amount, on: today)
    create(:expense, envelope: envelope, user: josh, amount: amount, transacted_on: on)
  end

  describe "an ordinary purchase" do
    subject(:notification) { described_class.new(log(20)) }

    it "tells the household who logged what, and what's left" do
      expect(notification.for_household).to include(
        title: "Josh logged $20.00 to Groceries",
        body:  "$80.00 left of $100.00 this month.",
        url:   "/envelopes/#{envelope.id}/expenses?month=#{today.month}&year=#{today.year}"
      )
    end

    it "sends nothing back to the person who logged it" do
      expect(notification.crossed).to be_nil
      expect(notification.for_logger).to be_nil
    end
  end

  describe "the purchase that makes a category nearly spent (90%)" do
    before { log(80) }
    subject(:notification) { described_class.new(log(10)) }

    it "leads with the warning for the household" do
      expect(notification.crossed).to eq(:low)
      expect(notification.for_household).to include(
        title: "Groceries is nearly spent",
        body:  "Josh logged $10.00. $10.00 left of $100.00 this month."
      )
    end

    it "warns the person who logged it too" do
      expect(notification.for_logger).to include(
        title: "Groceries is nearly spent",
        body:  "You logged $10.00. $10.00 left of $100.00 this month."
      )
    end
  end

  describe "the purchase that takes a category over budget" do
    before { log(95) }
    subject(:notification) { described_class.new(log(17.5)) }

    it "says it's over and by how much" do
      expect(notification.crossed).to eq(:over)
      expect(notification.for_household).to include(
        title: "Groceries is over budget",
        body:  "Josh logged $17.50. $12.50 over the $100.00 budget this month."
      )
      expect(notification.for_logger[:title]).to eq("Groceries is over budget")
    end
  end

  it "jumps straight to 'over' when one purchase skips 'nearly spent'" do
    expect(described_class.new(log(150)).crossed).to eq(:over)
  end

  it "spending exactly the budget is nearly spent, not over" do
    expect(described_class.new(log(100)).crossed).to eq(:low)
  end

  describe "once a category is already over" do
    before { log(120) }
    subject(:notification) { described_class.new(log(5)) }

    it "doesn't re-alert, but the household still hears about the purchase" do
      expect(notification.crossed).to be_nil
      expect(notification.for_logger).to be_nil
      expect(notification.for_household).to include(
        title: "Josh logged $5.00 to Groceries",
        body:  "$25.00 over the $100.00 budget this month."
      )
    end
  end

  it "judges each purchase by what was logged before it, not after" do
    first  = log(85)
    second = log(10)
    expect(described_class.new(first).crossed).to be_nil
    expect(described_class.new(second).crossed).to eq(:low)
  end

  it "never alerts for a category without a budget" do
    other = create(:envelope, account: account, name: "Gifts")
    expense = create(:expense, envelope: other, user: josh, amount: 500, transacted_on: today)
    notification = described_class.new(expense)

    expect(notification.crossed).to be_nil
    expect(notification.for_household[:body]).to eq("$500.00 spent this month.")
  end

  it "never alerts for a purchase backdated into a past month" do
    last_month = today.prev_month
    create(:envelope_budget, envelope: envelope, year: last_month.year, month: last_month.month, amount: 100)
    notification = described_class.new(log(150, on: last_month))

    expect(notification.crossed).to be_nil
    expect(notification.for_household[:body]).to eq("$50.00 over the $100.00 budget for #{last_month.strftime("%B")}.")
  end
end
