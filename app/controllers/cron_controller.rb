class CronController < ApplicationController
  skip_before_action :require_authentication, only: [:monthly_rollover, :purge_unconfirmed_meal_plans]
  skip_before_action :verify_authenticity_token, only: [:monthly_rollover, :purge_unconfirmed_meal_plans]
  skip_before_action :check_session_expiry, only: [:monthly_rollover, :purge_unconfirmed_meal_plans]
  before_action :authenticate_cron_token

  def monthly_rollover
    MonthlyRolloverJob.perform_later
    head :ok
  end

  def purge_unconfirmed_meal_plans
    PurgeUnconfirmedMealPlansJob.perform_later
    head :ok
  end

  private

  def authenticate_cron_token
    secret = Rails.application.credentials.cron_secret
    head :unauthorized and return if secret.blank?
    head :unauthorized and return unless ActiveSupport::SecurityUtils.secure_compare(
      request.headers["Authorization"].to_s,
      "Bearer #{secret}"
    )
  end
end
