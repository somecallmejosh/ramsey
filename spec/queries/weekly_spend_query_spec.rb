require "rails_helper"

RSpec.describe WeeklySpendQuery do
  let(:envelope)  { create(:envelope) }
  let(:other_env) { create(:envelope) }
  let(:user)      { create(:user) }
  subject(:query) { WeeklySpendQuery.new(envelope) }

  it "returns 8 entries" do
    expect(query.past_eight_weeks.size).to eq(8)
  end

  it "keys are ordered oldest to newest" do
    weeks = query.past_eight_weeks.keys
    expect(weeks).to eq(weeks.sort)
  end

  it "sums expenses in each week" do
    this_week_start = Date.current.beginning_of_week(:sunday)
    create(:expense, envelope: envelope, user: user,
           transacted_on: this_week_start, amount: 50.00)
    create(:expense, envelope: envelope, user: user,
           transacted_on: this_week_start + 2.days, amount: 30.00)

    result = query.past_eight_weeks
    expect(result[this_week_start]).to eq(80.00)
  end

  it "returns 0 for weeks with no expenses" do
    result = query.past_eight_weeks
    expect(result.values).to all(eq(0))
  end

  it "ignores expenses from other envelopes" do
    this_week_start = Date.current.beginning_of_week(:sunday)
    create(:expense, envelope: other_env, user: user,
           transacted_on: this_week_start, amount: 200.00)

    result = query.past_eight_weeks
    expect(result[this_week_start]).to eq(0)
  end
end
