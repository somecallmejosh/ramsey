class DebtsController < ApplicationController
  def index
    @snowball_debts = Debt.snowball.active.ordered
    @snowball_target = @snowball_debts.first
    @mortgage = Debt.mortgage.active.first
    @paid_off = Debt.paid_off.ordered
  end

  def show
    @debt = Debt.find(params[:id])
    @payments = @debt.debt_payments.includes(:user).order(paid_on: :desc, created_at: :desc)
    @chart_data = build_chart_data
  end

  private

  def build_chart_data
    points = { @debt.created_at.to_date => @debt.original_balance }
    @payments.reverse_each do |p|
      points[p.paid_on] = p.balance_after
    end
    points
  end
end
