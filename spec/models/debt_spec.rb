require "rails_helper"

RSpec.describe Debt, type: :model do
  describe "associations" do
    it { should have_many(:debt_payments).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:position) }
    it { should validate_numericality_of(:original_balance).is_greater_than_or_equal_to(0) }
    it { should validate_numericality_of(:current_balance).is_greater_than_or_equal_to(0) }
    it { should validate_numericality_of(:minimum_payment).is_greater_than_or_equal_to(0) }
  end

  describe "scopes" do
    it "active returns only debts without a paid_off_at" do
      active  = create(:debt)
      paid    = create(:debt, :paid_off)
      expect(Debt.active).to include(active)
      expect(Debt.active).not_to include(paid)
    end

    it "paid_off returns only debts with a paid_off_at" do
      active = create(:debt)
      paid   = create(:debt, :paid_off)
      expect(Debt.paid_off).to include(paid)
      expect(Debt.paid_off).not_to include(active)
    end

    it "snowball excludes mortgages" do
      personal = create(:debt)
      mortgage = create(:debt, :mortgage)
      expect(Debt.snowball).to include(personal)
      expect(Debt.snowball).not_to include(mortgage)
    end

    it "mortgage returns only mortgage-type debts" do
      personal = create(:debt)
      mortgage = create(:debt, :mortgage)
      expect(Debt.mortgage).to include(mortgage)
      expect(Debt.mortgage).not_to include(personal)
    end

    it "ordered sorts by position ascending" do
      d2 = create(:debt, position: 2)
      d1 = create(:debt, position: 1)
      expect(Debt.ordered.to_a).to eq([ d1, d2 ])
    end
  end

  describe "#paid_off?" do
    it "returns true when paid_off_at is set" do
      expect(build(:debt, :paid_off).paid_off?).to be true
    end

    it "returns false when paid_off_at is nil" do
      expect(build(:debt).paid_off?).to be false
    end
  end

  describe "#progress_pct" do
    it "returns 0 when nothing has been paid" do
      debt = build(:debt, original_balance: 10_000, current_balance: 10_000)
      expect(debt.progress_pct).to eq(0)
    end

    it "returns percentage of original balance paid off" do
      debt = build(:debt, original_balance: 10_000, current_balance: 7_500)
      expect(debt.progress_pct).to eq(25.0)
    end

    it "returns 0 when balance exceeds original (should not happen but is safe)" do
      debt = build(:debt, original_balance: 10_000, current_balance: 11_000)
      expect(debt.progress_pct).to eq(0)
    end

    it "returns 0 safely when original_balance is zero" do
      debt = build(:debt, original_balance: 0, current_balance: 0)
      expect(debt.progress_pct).to eq(0)
    end
  end
end
