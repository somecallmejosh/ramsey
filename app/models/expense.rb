class Expense < ApplicationRecord
  belongs_to :envelope
  belongs_to :user

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :transacted_on, presence: true,
                            comparison: { less_than_or_equal_to: -> { Date.current },
                                          message: "can't be in the future" }

  scope :current_month, -> {
    where(transacted_on: Date.current.beginning_of_month..Date.current.end_of_month)
  }

  scope :prior_month, -> {
    where("transacted_on < ?", Date.current.beginning_of_month)
  }

  scope :for_month, ->(year, month) {
    where(transacted_on: Date.new(year, month).all_month)
  }

  # How long the person who logged an expense can take it back, regardless of
  # the date it was logged against (powers the "Undo" toast).
  UNDO_WINDOW = 15.minutes

  RESTORE_PURPOSE = :restore_expense

  # A signed, short-lived copy of this expense so "Undo" after a delete can
  # put it back exactly as it was (same person, date and note).
  def restore_token
    self.class.restore_verifier.generate(
      attributes.slice("envelope_id", "user_id", "amount", "note", "transacted_on").transform_values(&:to_s)
        .merge("created_at" => created_at.iso8601(6)),
      purpose: RESTORE_PURPOSE, expires_in: UNDO_WINDOW
    )
  end

  def self.restore_from(token, envelope:)
    attrs = restore_verifier.verified(token, purpose: RESTORE_PURPOSE)
    return unless attrs && attrs["envelope_id"].to_i == envelope.id

    envelope.expenses.create(attrs.except("envelope_id"))
  end

  def self.restore_verifier
    Rails.application.message_verifier(RESTORE_PURPOSE)
  end

  def prior_month?
    transacted_on < Date.current.beginning_of_month
  end

  def deletable_by?(member)
    return false unless member
    return true if member.owner?
    return true if user_id == member.id && created_at && created_at > UNDO_WINDOW.ago

    !prior_month?
  end
end
