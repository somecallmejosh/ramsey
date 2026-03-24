require "rails_helper"

RSpec.describe Meal, type: :model do
  describe "associations" do
    it { should belong_to(:meal_plan) }
  end

  describe "validations" do
    subject { build(:meal) }

    it { should validate_presence_of(:dinner) }
    it { should validate_presence_of(:lunch) }
    it { should validate_inclusion_of(:day_of_week).in_range(0..6) }
    it { should validate_uniqueness_of(:day_of_week).scoped_to(:meal_plan_id) }
  end
end
