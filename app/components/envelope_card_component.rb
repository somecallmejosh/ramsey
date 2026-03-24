class EnvelopeCardComponent < ApplicationComponent
  def initialize(envelope:, budget:, spent:, current_user:, year:, month:)
    @envelope     = envelope
    @budget       = budget
    @spent        = spent
    @current_user = current_user
    @year         = year
    @month        = month
  end

  def remaining
    @budget - @spent
  end

  def over_budget?
    remaining.negative?
  end

  def admin?
    @current_user&.admin?
  end

  def budget_score
    return nil if @budget.zero?

    pct = @spent / @budget.to_f
    return 1 if pct > 1.0
    return 2 if pct > 0.9
    return 3 if pct > 0.75
    return 4 if pct > 0.5
    5
  end

  def current_month?
    @year == Date.current.year && @month == Date.current.month
  end

  def envelope_budget_for_edit
    @envelope.envelope_budgets.find_by(year: @year, month: @month)
  end
end
