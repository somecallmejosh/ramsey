class PurgeUnconfirmedMealPlansJob < ApplicationJob
  queue_as :default

  def perform
    MealPlan.where(confirmed_at: nil).where("created_at < ?", 24.hours.ago).find_each do |plan|
      plan.destroy
    end
  rescue NameError
    # MealPlan model not yet defined — skip silently in Phase 1
  end
end
