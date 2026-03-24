require "rails_helper"

RSpec.describe MonthlyRolloverJob, type: :job do
  let(:today) { Date.current }
  let(:this_year)  { today.year }
  let(:this_month) { today.month }
  let(:last_month) { today.last_month }

  def last_month_budget_for(envelope)
    EnvelopeBudget.find_by!(envelope: envelope, year: last_month.year, month: last_month.month)
  end

  def this_month_budget_for(envelope)
    EnvelopeBudget.find_by(envelope: envelope, year: this_year, month: this_month)
  end

  it "copies last month's budgets into the current month for active envelopes" do
    groceries = create(:envelope, name: "Groceries", active: true)
    create(:envelope_budget, :prior_month, envelope: groceries, amount: 700)

    described_class.perform_now

    budget = this_month_budget_for(groceries)
    expect(budget).to be_present
    expect(budget.amount).to eq(700)
  end

  it "does not create budgets for inactive envelopes" do
    inactive = create(:envelope, name: "Inactive", active: false)
    create(:envelope_budget, :prior_month, envelope: inactive, amount: 200)

    described_class.perform_now

    expect(this_month_budget_for(inactive)).to be_nil
  end

  it "is idempotent — running twice does not duplicate rows" do
    groceries = create(:envelope, name: "Groceries", active: true)
    create(:envelope_budget, :prior_month, envelope: groceries, amount: 700)

    described_class.perform_now
    described_class.perform_now

    count = EnvelopeBudget.where(
      envelope: groceries, year: this_year, month: this_month
    ).count
    expect(count).to eq(1)
  end

  it "does nothing when there are no last month budgets" do
    create(:envelope, name: "Groceries", active: true)

    expect { described_class.perform_now }.not_to raise_error
    expect(EnvelopeBudget.count).to eq(0)
  end

  it "copies all active envelopes" do
    groceries = create(:envelope, name: "Groceries", active: true)
    rent      = create(:envelope, name: "Rent",      active: true)
    create(:envelope_budget, :prior_month, envelope: groceries, amount: 700)
    create(:envelope_budget, :prior_month, envelope: rent,      amount: 1500)

    described_class.perform_now

    expect(this_month_budget_for(groceries).amount).to eq(700)
    expect(this_month_budget_for(rent).amount).to eq(1500)
  end
end
