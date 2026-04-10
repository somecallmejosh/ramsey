require "rails_helper"

RSpec.describe WeeklySpendQuery do
  let(:envelope)  { create(:envelope) }
  let(:other_env) { create(:envelope) }
  let(:user)      { create(:user) }
  subject(:query) { WeeklySpendQuery.new(envelope) }

  let(:year)  { Date.current.year }
  let(:month) { Date.current.month }

  it "keys are ordered oldest to newest" do
    weeks = query.for_month(year, month).keys
    expect(weeks).to eq(weeks.sort)
  end

  it "sums expenses in each week" do
    day = Date.new(year, month, 1)
    week_start = day.beginning_of_week(:sunday)
    week_end = week_start + 6.days
    label = "#{week_start.strftime("%-m/%d")}-#{week_end.strftime("%-m/%d")}"
    create(:expense, envelope: envelope, user: user,
           transacted_on: day, amount: 50.00)
    create(:expense, envelope: envelope, user: user,
           transacted_on: day + 1.day, amount: 30.00)

    result = query.for_month(year, month)
    expect(result[label]).to eq(80.00)
  end

  it "excludes expenses from other months" do
    last_month = Date.current.beginning_of_month - 1.day
    create(:expense, envelope: envelope, user: user,
           transacted_on: last_month, amount: 100.00)

    result = query.for_month(year, month)
    expect(result.values.sum).to eq(0)
  end

  it "ignores expenses from other envelopes" do
    day = Date.new(year, month, 1)
    create(:expense, envelope: other_env, user: user,
           transacted_on: day, amount: 200.00)

    result = query.for_month(year, month)
    expect(result.values.sum).to eq(0)
  end
end
