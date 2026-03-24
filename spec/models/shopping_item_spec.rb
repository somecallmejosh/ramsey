require "rails_helper"

RSpec.describe ShoppingItem, type: :model do
  describe "associations" do
    it { should belong_to(:meal_plan) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
  end

  describe "defaults" do
    it "defaults checked to false" do
      item = build(:shopping_item)
      expect(item.checked).to be false
    end

    it "defaults store to Aldi" do
      item = build(:shopping_item)
      expect(item.store).to eq("Aldi")
    end
  end
end
