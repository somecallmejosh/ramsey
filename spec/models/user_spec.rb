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

    it "requires passwords to be at least 8 characters" do
      expect(build(:user, password: "short12", password_confirmation: "short12")).not_to be_valid
      expect(build(:user, password: "longer12", password_confirmation: "longer12")).to be_valid
    end

    it "does not require a password when updating other fields" do
      user = create(:user)
      expect(User.find(user.id).update(email_address: "changed@example.com")).to be true
    end
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
