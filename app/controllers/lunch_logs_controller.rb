class LunchLogsController < ApplicationController
  before_action :set_lunch_log, only: [ :destroy ]

  def index
    @year          = (params[:year]  || Date.current.year).to_i
    @month         = (params[:month] || Date.current.month).to_i
    @selected_date = Date.new(@year, @month)
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
      head :unprocessable_content
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
