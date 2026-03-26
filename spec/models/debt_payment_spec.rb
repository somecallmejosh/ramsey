require "rails_helper"

RSpec.describe DebtPayment, type: :model do
  describe "associations" do
    it { should belong_to(:debt) }
    it { should belong_to(:user) }
  end

  describe "validations" do
    it { should validate_numericality_of(:amount).is_greater_than(0) }
    it { should validate_numericality_of(:balance_after).is_greater_than_or_equal_to(0) }
    it { should validate_presence_of(:paid_on) }

    it "rejects a future paid_on date" do
      payment = build(:debt_payment, paid_on: Date.tomorrow)
      expect(payment).not_to be_valid
      expect(payment.errors[:paid_on]).to be_present
    end

    it "accepts today as paid_on" do
      payment = build(:debt_payment, paid_on: Date.current)
      expect(payment).to be_valid
    end
  end

  describe "after_create sync_debt_balance" do
    let(:debt) { create(:debt, original_balance: 10_000, current_balance: 10_000) }
    let(:user) { create(:user) }

    it "updates debt current_balance to balance_after" do
      create(:debt_payment, debt: debt, user: user, amount: 500, balance_after: 9_500)
      expect(debt.reload.current_balance).to eq(9_500)
    end

    it "sets paid_off_at when balance_after is zero" do
      create(:debt_payment, debt: debt, user: user, amount: 10_000, balance_after: 0)
      expect(debt.reload.paid_off_at).to eq(Date.current)
    end

    it "clears paid_off_at when balance_after is non-zero" do
      debt.update_columns(paid_off_at: Date.current)
      create(:debt_payment, debt: debt, user: user, amount: 100, balance_after: 500)
      expect(debt.reload.paid_off_at).to be_nil
    end
  end
end
