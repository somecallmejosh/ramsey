require "rails_helper"

RSpec.describe LunchLog, type: :model do
  let(:user)       { create(:user) }
  let(:other_user) { create(:user) }

  describe "associations" do
    it { should belong_to(:user) }
  end

  describe "validations" do
    it { should validate_presence_of(:logged_on) }

    it "rejects duplicate logged_on for the same user" do
      create(:lunch_log, user: user, logged_on: Date.new(2026, 3, 3))
      duplicate = build(:lunch_log, user: user, logged_on: Date.new(2026, 3, 3))
      expect(duplicate).not_to be_valid
    end

    it "allows the same date for different users" do
      create(:lunch_log, user: user, logged_on: Date.new(2026, 3, 3))
      other = build(:lunch_log, user: other_user, logged_on: Date.new(2026, 3, 3))
      expect(other).to be_valid
    end
  end

  describe ".for_month" do
    it "returns logs in the given month" do
      create(:lunch_log, user: user, logged_on: Date.new(2026, 3, 3))
      expect(LunchLog.for_month(2026, 3).count).to eq(1)
    end

    it "excludes logs in other months" do
      create(:lunch_log, user: user, logged_on: Date.new(2026, 2, 28))
      expect(LunchLog.for_month(2026, 3).count).to eq(0)
    end
  end

  describe "SAVINGS_PER_LUNCH" do
    it "is $8" do
      expect(LunchLog::SAVINGS_PER_LUNCH).to eq(8)
    end
  end

  describe "savings calculation" do
    it "computes correctly for multiple days" do
      create(:lunch_log, user: user, logged_on: Date.new(2026, 3, 3))
      create(:lunch_log, user: user, logged_on: Date.new(2026, 3, 4))
      days = LunchLog.where(user: user).for_month(2026, 3).count
      expect(days * LunchLog::SAVINGS_PER_LUNCH).to eq(16)
    end

    it "ignores other users' logs" do
      create(:lunch_log, user: other_user, logged_on: Date.new(2026, 3, 3))
      days = LunchLog.where(user: user).for_month(2026, 3).count
      expect(days).to eq(0)
    end
  end
end
