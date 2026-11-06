class Invitation < ApplicationRecord
  belongs_to :account
  belongs_to :invited_by, class_name: "User"

  # How long a new invite link works. Shown on the invitations page.
  VALID_FOR = 7.days

  has_secure_token :token

  validates :expires_at, presence: true

  scope :pending, -> { where(accepted_at: nil).where("expires_at > ?", Time.current) }

  def expired? = expires_at < Time.current
  def accepted? = accepted_at.present?
end
