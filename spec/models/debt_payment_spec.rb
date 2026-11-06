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

    it "sets paid_off_at to the payment date when balance_after is zero" do
      create(:debt_payment, debt: debt, user: user, amount: 10_000, balance_after: 0)
      expect(debt.reload.paid_off_at).to eq(Date.current)
    end

    it "clears paid_off_at when balance_after is non-zero" do
      debt.update_columns(paid_off_at: Date.current)
      create(:debt_payment, debt: debt, user: user, amount: 100, balance_after: 500)
      expect(debt.reload.paid_off_at).to be_nil
    end
  end

  describe "balance sync" do
    let(:user) { create(:user) }
    let(:debt) { create(:debt, original_balance: 5_000, current_balance: 3_000) }

    def pay(amount, balance_after, paid_on = Date.current)
      create(:debt_payment, debt: debt, user: user, amount: amount,
                            balance_after: balance_after, paid_on: paid_on)
    end

    it "records the balance before the payment" do
      payment = pay(100, 2_900)
      expect(payment.balance_before).to eq(3_000)
    end

    context "when the new balance is left blank" do
      it "takes the amount off the current balance" do
        payment = pay(250, nil)
        expect(payment.balance_after).to eq(2_750)
        expect(debt.reload.current_balance).to eq(2_750)
      end

      it "never goes below zero, and marks the debt paid off" do
        pay(5_000, nil)
        expect(debt.reload.current_balance).to eq(0)
        expect(debt).to be_paid_off
      end

      it "takes a backdated amount off the balance as of that date" do
        pay(100, 2_900, 2.days.ago.to_date)
        older = pay(50, nil, 5.days.ago.to_date)
        expect(older.balance_after).to eq(4_950)
        expect(debt.reload.current_balance).to eq(2_900)
      end

      it "is still invalid without an amount" do
        payment = build(:debt_payment, debt: debt, user: user, amount: nil, balance_after: nil)
        expect(payment).not_to be_valid
        expect(payment.errors[:balance_after]).to be_present
      end
    end

    it "does not move the balance for a backdated payment older than the latest" do
      pay(100, 2_900, 2.days.ago.to_date)
      pay(50, 2_950, 5.days.ago.to_date)
      expect(debt.reload.current_balance).to eq(2_900)
    end

    context "on destroy" do
      it "restores the balance from before the only payment (not the original balance)" do
        payment = pay(100, 2_900)
        payment.destroy!
        expect(debt.reload.current_balance).to eq(3_000)
      end

      it "restores the previous payment's balance when the latest is removed" do
        pay(100, 2_900, 3.days.ago.to_date)
        latest = pay(200, 2_700, 1.day.ago.to_date)
        latest.destroy!
        expect(debt.reload.current_balance).to eq(2_900)
      end

      it "leaves the balance alone when an older payment is removed" do
        older = pay(100, 2_900, 3.days.ago.to_date)
        pay(200, 2_700, 1.day.ago.to_date)
        older.destroy!
        expect(debt.reload.current_balance).to eq(2_700)
      end

      it "falls back to the previous payment, then the original balance, for legacy rows" do
        first = pay(100, 2_900, 3.days.ago.to_date)
        latest = pay(200, 2_700, 1.day.ago.to_date)
        DebtPayment.update_all(balance_before: nil)

        latest.reload.destroy!
        expect(debt.reload.current_balance).to eq(2_900)

        first.reload.destroy!
        expect(debt.reload.current_balance).to eq(5_000)
      end

      it "clears paid_off_at when the payoff payment is removed" do
        payoff = pay(3_000, 0)
        expect(debt.reload.paid_off_at).to eq(Date.current)

        payoff.destroy!
        expect(debt.reload.current_balance).to eq(3_000)
        expect(debt.paid_off_at).to be_nil
      end

      it "does not touch the debt when the debt itself is destroyed" do
        pay(100, 2_900)
        expect { debt.destroy! }.not_to raise_error
      end
    end

    describe "#balance_if_removed" do
      it "is the restored balance for the latest payment and the current balance otherwise" do
        older = pay(100, 2_900, 3.days.ago.to_date)
        latest = pay(200, 2_700, 1.day.ago.to_date)
        expect(latest.balance_if_removed).to eq(2_900)
        expect(older.balance_if_removed).to eq(2_700)
      end
    end
  end
end
