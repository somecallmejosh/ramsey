require "rails_helper"

RSpec.describe BudgetMonth do
  let(:account) { create(:account) }
  let(:other)   { create(:account) }
  let(:user)    { create(:user, account: account) }
  let!(:groceries) { create(:envelope, account: account, name: "Groceries", position: 1) }
  let!(:gas)       { create(:envelope, account: account, name: "Gas", position: 2) }

  before do
    create(:envelope_budget, envelope: groceries, year: Date.current.year, month: Date.current.month, amount: 500)
    create(:envelope_budget, envelope: gas, year: Date.current.year, month: Date.current.month, amount: 100)
    create(:expense, envelope: groceries, user: user, amount: 120)
    create(:expense, envelope: gas, user: user, amount: 30)
    create(:expense, envelope: gas, user: user, amount: 999, transacted_on: Date.current.last_month)
    create(:expense, envelope: create(:envelope, account: other), amount: 50)
  end

  subject(:month) { described_class.new(account) }

  it "totals only this account's current month" do
    expect(month.total_budget).to eq(600)
    expect(month.total_spent).to eq(150)
    expect(month.total_left).to eq(450)
    expect(month.spent_for(gas)).to eq(30)
  end

  it "lists recent expenses newest first, scoped to the account and month" do
    expect(month.recent_expenses.map(&:amount)).to eq([ 30, 120 ])
  end

  it "only allows going forward from a past month" do
    expect(month.next_date).to be_nil
    expect(described_class.new(account, Date.current.last_month).next_date).to eq(Date.current.beginning_of_month)
  end
end
