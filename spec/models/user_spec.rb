require "rails_helper"

RSpec.describe User, type: :model do
  describe "associations" do
    it { should have_many(:sessions).dependent(:destroy) }
    it { should have_many(:expenses).dependent(:destroy) }
    # meal_plans, lunch_logs, push_subscriptions tested in their respective phase specs
  end

  describe "validations" do
    it { should validate_presence_of(:email_address) }
    it { should have_secure_password }
  end

  describe "role enum" do
    it "defaults to standard" do
      user = build(:user)
      expect(user.role).to eq("standard")
    end

    it "can be set to admin" do
      user = build(:user, :admin)
      expect(user.role).to eq("admin")
    end
  end

  describe "#admin?" do
    it "returns true for admin users" do
      expect(build(:user, :admin).admin?).to be true
    end

    it "returns false for standard users" do
      expect(build(:user).admin?).to be false
    end
  end

  describe ".admin scope" do
    it "returns only admin users" do
      admin  = create(:user, :admin)
      _other = create(:user)
      expect(User.admin).to contain_exactly(admin)
    end
  end
end
