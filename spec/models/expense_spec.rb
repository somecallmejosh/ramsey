require "rails_helper"

RSpec.describe Expense, type: :model do
  describe "associations" do
    it { should belong_to(:envelope) }
    it { should belong_to(:user) }
  end

  describe "validations" do
    it { should validate_presence_of(:amount) }
    it { should validate_presence_of(:transacted_on) }
    it { should validate_numericality_of(:amount).is_greater_than(0) }

    it "rejects future-dated transactions" do
      expense = build(:expense, transacted_on: Date.current + 1.day)
      expect(expense).not_to be_valid
      expect(expense.errors[:transacted_on]).to include("cannot be a future date")
    end

    it "accepts today's date" do
      expense = build(:expense, transacted_on: Date.current)
      expect(expense).to be_valid
    end
  end

  describe "scopes" do
    let(:envelope) { create(:envelope) }
    let(:user)     { create(:user) }

    it "current_month returns only this month's expenses" do
      current = create(:expense, envelope: envelope, user: user, transacted_on: Date.current)
      prior   = create(:expense, :prior_month, envelope: envelope, user: user)
      expect(Expense.current_month).to include(current)
      expect(Expense.current_month).not_to include(prior)
    end

    it "prior_month returns only expenses before this month" do
      current = create(:expense, envelope: envelope, user: user, transacted_on: Date.current)
      prior   = create(:expense, :prior_month, envelope: envelope, user: user)
      expect(Expense.prior_month).to include(prior)
      expect(Expense.prior_month).not_to include(current)
    end
  end

  describe "#prior_month?" do
    it "returns true for last month's expense" do
      expense = build(:expense, :prior_month)
      expect(expense.prior_month?).to be true
    end

    it "returns false for today's expense" do
      expense = build(:expense, transacted_on: Date.current)
      expect(expense.prior_month?).to be false
    end
  end
end
