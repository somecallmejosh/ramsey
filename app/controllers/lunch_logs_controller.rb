class LunchLogsController < ApplicationController
  before_action :set_lunch_log, only: [ :destroy ]

  def index
    @selected_date = selected_month
    @year          = @selected_date.year
    @month         = @selected_date.month
    @logs          = current_user.lunch_logs.for_month(@year, @month)
    load_stats(@year, @month)
  end

  def create
    @lunch_log = current_user.lunch_logs.build(logged_on: params[:logged_on])
    if @lunch_log.save
      year  = @lunch_log.logged_on.year
      month = @lunch_log.logged_on.month
      @logs = current_user.lunch_logs.for_month(year, month)
      load_stats(year, month)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to lunch_logs_path }
      end
    else
      @error = @lunch_log.errors.map(&:message).first || "Couldn't log that day. Please try again."
      respond_to do |format|
        format.turbo_stream { render :create_failed, status: :unprocessable_content }
        format.html { redirect_to lunch_logs_path, alert: @error }
      end
    end
  end

  def destroy
    date = @lunch_log.logged_on
    @lunch_log.destroy!
    @lunch_log = LunchLog.new(logged_on: date)
    @logs = current_user.lunch_logs.for_month(date.year, date.month)
    load_stats(date.year, date.month)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to lunch_logs_path }
    end
  end

  private

  # The month in the URL, or this month. Never a future month.
  def selected_month
    month = Date.new(params[:year].to_i, params[:month].to_i) if params[:year].present? && params[:month].present?
    [ month || Date.current, Date.current ].min.beginning_of_month
  rescue Date::Error
    Date.current.beginning_of_month
  end

  def set_lunch_log
    @lunch_log = current_user.lunch_logs.find(params[:id])
  end

  def load_stats(year, month)
    @days_packed         = current_user.lunch_logs.for_month(year, month).count
    @estimated_savings   = @days_packed * LunchLog::SAVINGS_PER_LUNCH
    @work_meals_envelope = current_account.envelopes.find_by(name: "Work Meals")
    return unless @work_meals_envelope

    budget                = EnvelopeBudget.find_by(envelope: @work_meals_envelope, year: year, month: month)
    @work_meals_budget    = budget&.amount.to_d
    @work_meals_spent     = @work_meals_envelope.expenses.for_month(year, month).sum(:amount)
    @work_meals_remaining = @work_meals_budget - @work_meals_spent
  end
end
