class DashboardController < ApplicationController
  def index
    year  = params[:year]&.to_i  || Date.current.year
    month = params[:month]&.to_i || Date.current.month

    @selected_date  = Date.new(year, month)
    @current_month  = @selected_date == Date.current.beginning_of_month.change(day: 1)
    @envelopes      = current_account.envelopes.active.ordered

    @budgets = EnvelopeBudget
      .where(envelope_id: @envelopes.select(:id), year: year, month: month)
      .pluck(:envelope_id, :amount)
      .to_h

    @totals = Expense
      .where(envelope_id: @envelopes.select(:id), transacted_on: @selected_date.all_month)
      .group(:envelope_id)
      .sum(:amount)

    @year  = year
    @month = month

    @snowball_debts  = current_account.debts.snowball.active.ordered
    @snowball_target = @snowball_debts.first
    @total_snowball  = @snowball_debts.sum(:current_balance)
  end
end
