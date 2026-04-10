require "rails_helper"

RSpec.describe User, type: :model do
  describe "associations" do
    it { should belong_to(:account) }
    it { should have_many(:sessions).dependent(:destroy) }
    it { should have_many(:expenses).dependent(:destroy) }
    # meal_plans, lunch_logs, push_subscriptions tested in their respective phase specs
  end

  describe "validations" do
    it { should validate_presence_of(:email_address) }
    it { should have_secure_password }
  end

  describe "role enum" do
    it "defaults to member" do
      user = build(:user)
      expect(user.role).to eq("member")
    end

    it "can be set to owner" do
      user = build(:user, :owner)
      expect(user.role).to eq("owner")
    end
  end

  describe "#owner?" do
    it "returns true for owner users" do
      expect(build(:user, :owner).owner?).to be true
    end

    it "returns false for member users" do
      expect(build(:user).owner?).to be false
    end
  end

  describe ".owner scope" do
    it "returns only owner users" do
      owner  = create(:user, :owner)
      _other = create(:user)
      expect(User.owner).to contain_exactly(owner)
    end
  end
end
