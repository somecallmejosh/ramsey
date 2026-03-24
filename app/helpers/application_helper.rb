module ApplicationHelper
  include UiHelper
  include IconHelper

  # Returns the remaining grocery budget for the current month.
  # Used by the meal planner to show how much is left to spend on groceries.
  def current_groceries_remaining
    groceries = Envelope.find_by(name: "Groceries")
    return 0 unless groceries

    today = Date.current
    budget = EnvelopeBudget.find_by(envelope: groceries, year: today.year, month: today.month)&.amount || 0
    spent  = Expense.where(envelope: groceries, transacted_on: today.all_month).sum(:amount)

    budget - spent
  end
end
