class DashboardController < ApplicationController
  def index
    year  = params[:year]&.to_i  || Date.current.year
    month = params[:month]&.to_i || Date.current.month

    @selected_date  = Date.new(year, month)
    @current_month  = @selected_date == Date.current.beginning_of_month.change(day: 1)
    @envelopes      = Envelope.active.ordered

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
  end
end
