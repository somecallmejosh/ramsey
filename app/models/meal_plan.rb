class MealPlan < ApplicationRecord
  belongs_to :user
  belongs_to :account
  has_many :meals, dependent: :destroy
  has_many :shopping_items, dependent: :destroy
  has_many_attached :pantry_images, dependent: :purge_later

  validates :week_start, presence: true, uniqueness: { scope: :account_id }
  validate  :week_start_must_be_sunday
  validate  :confirmed_at_not_cleared_after_set
  validate  :pantry_images_within_size_limit

  STATUSES = %w[pending processing ready failed].freeze

  # Matches the hint on the form. Larger photos are rejected by the Claude API.
  MAX_IMAGE_BYTES = (3.75 * 1024 * 1024).to_i

  # How long generation can run before we tell the user it's slow.
  SLOW_AFTER = 2.minutes

  scope :confirmed,   -> { where.not(confirmed_at: nil) }
  scope :unconfirmed, -> { where(confirmed_at: nil) }

  def confirmed? = confirmed_at.present?
  def pending?   = status == "pending"
  def processing? = status == "processing"
  def ready?     = status == "ready"
  def failed?    = status == "failed"

  def current_week?
    week_start == Date.current.beginning_of_week(:sunday)
  end

  def taking_too_long?
    (pending? || processing?) && created_at.present? && created_at < SLOW_AFTER.ago
  end

  private

  def week_start_must_be_sunday
    return if week_start.blank?
    errors.add(:week_start, "must be a Sunday") unless week_start.sunday?
  end

  def pantry_images_within_size_limit
    too_big = pantry_images.reject { |image| image.blob.byte_size.to_i <= MAX_IMAGE_BYTES }
    return if too_big.empty?

    names = too_big.map { |image| image.blob.filename.to_s }.to_sentence
    errors.add(:base, "#{names} #{too_big.one? ? "is" : "are"} too large. Each photo must be 3.75 MB or smaller.")
  end

  def confirmed_at_not_cleared_after_set
    if confirmed_at_was.present? && confirmed_at.nil?
      errors.add(:confirmed_at, "cannot be cleared after confirmation")
    end
  end
end
