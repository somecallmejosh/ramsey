# One month of an account's budget: envelopes, what was budgeted, what was
# spent, and recent activity. Shared by the dashboard and the expense Turbo
# Streams so a logged purchase re-renders exactly what the dashboard shows.
class BudgetMonth
  RECENT_LIMIT = 5

  attr_reader :date

  def initialize(account, date = Date.current)
    @account = account
    @date    = date.beginning_of_month
  end

  def year  = date.year
  def month = date.month

  def current?
    date == Date.current.beginning_of_month
  end

  def previous_date = date.prev_month
  def next_date     = current? ? nil : date.next_month

  def envelopes
    @envelopes ||= @account.envelopes.active.ordered.to_a
  end

  def budget_for(envelope) = budgets[envelope.id] || 0
  def spent_for(envelope)  = spent[envelope.id] || 0

  def total_budget = budgets.values.sum
  def total_spent  = spent.values.sum
  def total_left   = total_budget - total_spent

  def recent_expenses
    @recent_expenses ||= Expense
      .where(envelope_id: envelopes.map(&:id), transacted_on: date.all_month)
      .includes(:user, :envelope)
      .order(created_at: :desc)
      .limit(RECENT_LIMIT)
      .to_a
  end

  private

  def budgets
    @budgets ||= EnvelopeBudget
      .where(envelope_id: envelopes.map(&:id), year: year, month: month)
      .pluck(:envelope_id, :amount)
      .to_h
  end

  def spent
    @spent ||= Expense
      .where(envelope_id: envelopes.map(&:id), transacted_on: date.all_month)
      .group(:envelope_id)
      .sum(:amount)
  end
end
