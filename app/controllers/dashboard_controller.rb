class DashboardController < ApplicationController
  def index
    date = if params[:year] && params[:month]
      Date.new(params[:year].to_i, params[:month].to_i.clamp(1, 12))
    else
      Date.current
    end
    date = Date.current if date > Date.current

    @budget_month = BudgetMonth.new(current_account, date)

    @snowball_debts  = current_account.debts.snowball.active.ordered
    @snowball_target = @snowball_debts.first
    @total_snowball  = @snowball_debts.sum(:current_balance)
  end
end
