class Session < ApplicationRecord
  # Household budgeting is an every-few-days habit. A short idle timeout turns
  # "log a purchase" into "remember your password", so keep people signed in.
  IDLE_TIMEOUT = 60.days

  belongs_to :user

  def idle_expired?
    last_active_at&.before?(IDLE_TIMEOUT.ago)
  end
end
