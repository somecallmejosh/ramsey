require "rails_helper"

RSpec.describe Envelope, type: :model do
  describe "associations" do
    it { should have_many(:envelope_budgets).dependent(:destroy) }
    it { should have_many(:expenses).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:position) }
  end

  describe "scopes" do
    it "active scope returns only active envelopes" do
      active   = create(:envelope, active: true)
      inactive = create(:envelope, active: false)
      expect(Envelope.active).to include(active)
      expect(Envelope.active).not_to include(inactive)
    end

    it "ordered scope returns envelopes by position" do
      e2 = create(:envelope, position: 2)
      e1 = create(:envelope, position: 1)
      expect(Envelope.ordered.to_a).to eq([ e1, e2 ])
    end
  end

  describe "#budget_for" do
    it "returns the budget amount for the given month" do
      envelope = create(:envelope)
      create(:envelope_budget, envelope: envelope, year: 2026, month: 3, amount: 700)
      expect(envelope.budget_for(year: 2026, month: 3)).to eq(700)
    end

    it "returns 0 when no budget exists for the month" do
      envelope = create(:envelope)
      expect(envelope.budget_for(year: 2026, month: 3)).to eq(0)
    end
  end

  describe "#spent_in" do
    it "sums expenses for the given month" do
      envelope = create(:envelope)
      user     = create(:user)
      create(:expense, envelope: envelope, user: user, amount: 50, transacted_on: Date.new(2026, 3, 10))
      create(:expense, envelope: envelope, user: user, amount: 30, transacted_on: Date.new(2026, 3, 20))
      create(:expense, envelope: envelope, user: user, amount: 99, transacted_on: Date.new(2026, 2, 28))
      expect(envelope.spent_in(year: 2026, month: 3)).to eq(80)
    end

    it "returns 0 when no expenses exist for the month" do
      envelope = create(:envelope)
      expect(envelope.spent_in(year: 2026, month: 3)).to eq(0)
    end
  end
end
