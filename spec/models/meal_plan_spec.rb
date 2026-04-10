require "rails_helper"

RSpec.describe MealPlan, type: :model do
  describe "associations" do
    it { should belong_to(:user) }
    it { should have_many(:meals).dependent(:destroy) }
    it { should have_many(:shopping_items).dependent(:destroy) }
  end

  describe "validations" do
    subject { build(:meal_plan) }

    it { should validate_presence_of(:week_start) }
    it { should validate_uniqueness_of(:week_start).scoped_to(:account_id) }
  end

  describe "week_start must be a Sunday" do
    it "is valid when week_start is a Sunday" do
      plan = build(:meal_plan, week_start: Date.new(2026, 3, 22)) # Sunday
      expect(plan).to be_valid
    end

    it "is invalid when week_start is not a Sunday" do
      plan = build(:meal_plan, week_start: Date.new(2026, 3, 23)) # Monday
      expect(plan).not_to be_valid
      expect(plan.errors[:week_start]).to include("must be a Sunday")
    end
  end

  describe "confirmed_at cannot be cleared once set" do
    it "prevents confirmed_at from being cleared after it was set" do
      user = create(:user)
      plan = create(:meal_plan, :confirmed, user: user)
      plan.confirmed_at = nil
      expect(plan).not_to be_valid
      expect(plan.errors[:confirmed_at]).to include("cannot be cleared after confirmation")
    end

    it "allows setting confirmed_at when it was nil" do
      user = create(:user)
      plan = create(:meal_plan, user: user)
      plan.confirmed_at = Time.current
      expect(plan).to be_valid
    end
  end

  describe "#confirmed?" do
    it "returns true when confirmed_at is set" do
      plan = build(:meal_plan, :confirmed)
      expect(plan.confirmed?).to be true
    end

    it "returns false when confirmed_at is nil" do
      plan = build(:meal_plan)
      expect(plan.confirmed?).to be false
    end
  end
end
