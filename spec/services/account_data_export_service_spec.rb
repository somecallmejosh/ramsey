require "rails_helper"
require "csv"

RSpec.describe AccountDataExportService do
  let(:account) { create(:account) }
  let(:owner)   { create(:user, :owner, account: account) }

  describe "#call" do
    it "returns a successful result with CSV data" do
      result = described_class.new(account: account).call

      expect(result).to be_success
      expect(result.csv).to be_present
      expect(result.error).to be_nil
    end

    it "includes user data without password" do
      owner # ensure created
      result = described_class.new(account: account).call

      expect(result.csv).to include(owner.email_address)
      expect(result.csv).to include("owner")
      expect(result.csv).not_to include(owner.password_digest)
    end

    it "includes envelope data" do
      envelope = create(:envelope, account: account, name: "Groceries")
      result = described_class.new(account: account).call

      expect(result.csv).to include("Groceries")
    end

    it "includes envelope budget data" do
      envelope = create(:envelope, account: account, name: "Groceries")
      EnvelopeBudget.create!(envelope: envelope, year: 2026, month: 4, amount: 500)
      result = described_class.new(account: account).call

      expect(result.csv).to include("Envelope Budgets")
      expect(result.csv).to include("500.0")
    end

    it "includes expense data" do
      envelope = create(:envelope, account: account, name: "Groceries")
      Expense.create!(envelope: envelope, user: owner, amount: 42.50, note: "Weekly shop", transacted_on: Date.current)
      result = described_class.new(account: account).call

      expect(result.csv).to include("Weekly shop")
      expect(result.csv).to include("42.5")
    end

    it "includes debt and debt payment data" do
      debt = create(:debt, account: account, name: "Car Loan")
      DebtPayment.create!(debt: debt, user: owner, amount: 200, balance_after: 9800, paid_on: Date.current, note: "March payment")
      result = described_class.new(account: account).call

      expect(result.csv).to include("Car Loan")
      expect(result.csv).to include("March payment")
    end

    it "includes meal plan and related data" do
      plan = create(:meal_plan, account: account, user: owner, week_start: Date.new(2026, 4, 5), status: "ready", confirmed_at: Time.current)
      Meal.create!(meal_plan: plan, day_of_week: 0, lunch: "Sandwich", dinner: "Pasta", prep_note: "Easy")
      ShoppingItem.create!(meal_plan: plan, name: "Bread", quantity: "1 loaf", store: "Aldi")
      result = described_class.new(account: account).call

      expect(result.csv).to include("Sandwich")
      expect(result.csv).to include("Bread")
    end

    it "includes lunch log data" do
      LunchLog.create!(user: owner, logged_on: Date.current)
      result = described_class.new(account: account).call

      expect(result.csv).to include("Lunch Logs")
      expect(result.csv).to include(owner.email_address)
    end

    it "includes section headers" do
      result = described_class.new(account: account).call

      %w[Users Envelopes Expenses Debts Meals].each do |section|
        expect(result.csv).to include(section)
      end
    end
  end
end
