class ExpenseRowComponent < ApplicationComponent
  def initialize(expense:, current_user:)
    @expense      = expense
    @current_user = current_user
  end

  def can_delete?
    @expense.deletable_by?(@current_user)
  end

  def amount
    helpers.number_to_currency(@expense.amount)
  end

  def envelope
    @expense.envelope
  end
end
