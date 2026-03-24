class MealPlannerJob < ApplicationJob
  queue_as :default

  def perform(meal_plan_id, message, groceries_remaining)
    meal_plan = MealPlan.find_by(id: meal_plan_id)
    return unless meal_plan

    meal_plan.update!(status: "processing")

    images = encode_images(meal_plan)
    result = MealPlannerService.new(
      message:             message,
      groceries_remaining: groceries_remaining,
      images:              images
    ).call

    if result.success?
      meal_plan.update!(
        status:      "ready",
        ai_response: { meals: result.meals, shopping_items: result.shopping_items }
      )
    else
      meal_plan.update!(status: "failed", error_message: result.error)
    end
  rescue => e
    meal_plan&.update_columns(status: "failed", error_message: "An unexpected error occurred. Please try again.", updated_at: Time.current)
    raise
  end

  private

  def encode_images(meal_plan)
    return [] unless meal_plan.pantry_images.attached?

    meal_plan.pantry_images.map do |image|
      {
        content_type: image.content_type,
        data:         Base64.strict_encode64(image.blob.download)
      }
    end
  end
end
