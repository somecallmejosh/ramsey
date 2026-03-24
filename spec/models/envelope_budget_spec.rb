require "rails_helper"

RSpec.describe EnvelopeBudget, type: :model do
  describe "associations" do
    it { should belong_to(:envelope) }
  end

  describe "validations" do
    subject { build(:envelope_budget) }

    it { should validate_presence_of(:year) }
    it { should validate_presence_of(:month) }
    it { should validate_presence_of(:amount) }
    it { should validate_numericality_of(:amount).is_greater_than_or_equal_to(0) }
    it { should validate_uniqueness_of(:month).scoped_to(:envelope_id, :year) }
  end

  describe "prior month protection" do
    it "prevents updating a prior month budget" do
      envelope = create(:envelope)
      prior    = create(:envelope_budget, :prior_month, envelope: envelope, amount: 500)
      prior.update(amount: 600)
      expect(prior.reload.amount).to eq(500)
      expect(prior.errors[:base]).to include("Cannot modify a prior month's budget")
    end

    it "allows updating a current month budget" do
      envelope = create(:envelope)
      current  = create(:envelope_budget, envelope: envelope,
                        year: Date.current.year, month: Date.current.month, amount: 500)
      expect { current.update!(amount: 600) }.not_to raise_error
      expect(current.reload.amount).to eq(600)
    end
  end
end
