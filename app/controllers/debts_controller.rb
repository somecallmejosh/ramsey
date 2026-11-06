class DebtsController < ApplicationController
  def index
    @snowball_debts = current_account.debts.snowball.active.ordered
    @snowball_target = @snowball_debts.first
    @mortgage = current_account.debts.mortgage.active.first
    @paid_off = current_account.debts.paid_off.ordered
  end

  def show
    @debt = current_account.debts.find(params[:id])
    @payments = @debt.debt_payments.includes(:user).order(paid_on: :desc, created_at: :desc, id: :desc).to_a
    # Only removing the newest payment changes the balance; older ones leave it as is.
    @balance_if_latest_removed = @payments.first&.balance_if_removed
    @chart_data = build_chart_data
    @chart_summary = build_chart_summary
  end

  private

  # Balance after each payment, oldest first, starting from the original
  # balance. Keyed by date; the view turns dates into text labels because
  # the app ships Chart.js without a date adapter.
  def build_chart_data
    points = @payments.sort_by { |p| [ p.paid_on, p.created_at ] }.to_h { |p| [ p.paid_on, p.balance_after ] }
    start  = [ @debt.created_at.to_date, points.keys.first&.prev_day ].compact.min
    { start => @debt.original_balance }.merge(points)
  end

  def build_chart_summary
    (first_on, first_balance), (last_on, last_balance) = @chart_data.first, @chart_data.to_a.last
    fmt = ->(date) { date.strftime("%b %-d, %Y") }
    "Went from #{helpers.number_to_currency(first_balance)} on #{fmt.(first_on)} " \
      "to #{helpers.number_to_currency(last_balance)} on #{fmt.(last_on)}."
  end
end
