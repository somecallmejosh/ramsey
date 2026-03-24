require "image_processing/mini_magick"

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

  HEIC_TYPES = %w[image/heic image/heif].freeze

  def encode_images(meal_plan)
    return [] unless meal_plan.pantry_images.attached?

    meal_plan.pantry_images.map do |image|
      blob = image.blob

      if HEIC_TYPES.include?(blob.content_type.to_s.downcase)
        blob.open do |tmp|
          processed = ImageProcessing::MiniMagick.source(tmp).convert("jpeg").call
          { content_type: "image/jpeg", data: Base64.strict_encode64(processed.read) }
        end
      else
        { content_type: blob.content_type, data: Base64.strict_encode64(blob.download) }
      end
    end
  end
end
