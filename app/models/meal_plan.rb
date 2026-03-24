class MealPlan < ApplicationRecord
  belongs_to :user
  has_many :meals, dependent: :destroy
  has_many :shopping_items, dependent: :destroy
  has_many_attached :pantry_images, dependent: :purge_later

  validates :week_start, presence: true, uniqueness: true
  validate  :week_start_must_be_sunday
  validate  :confirmed_at_not_cleared_after_set

  scope :confirmed,   -> { where.not(confirmed_at: nil) }
  scope :unconfirmed, -> { where(confirmed_at: nil) }

  def confirmed?
    confirmed_at.present?
  end

  private

  def week_start_must_be_sunday
    return if week_start.blank?
    errors.add(:week_start, "must be a Sunday") unless week_start.sunday?
  end

  def confirmed_at_not_cleared_after_set
    if confirmed_at_was.present? && confirmed_at.nil?
      errors.add(:confirmed_at, "cannot be cleared after confirmation")
    end
  end
end
