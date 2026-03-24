class ExpenseRowComponent < ApplicationComponent
  def initialize(expense:, current_user:)
    @expense      = expense
    @current_user = current_user
  end

  def can_delete?
    return true if @current_user&.admin?
    !@expense.prior_month?
  end

  def envelope
    @expense.envelope
  end
end
