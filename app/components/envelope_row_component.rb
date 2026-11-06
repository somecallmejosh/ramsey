# One category on the dashboard. The row links to the category's page
# (purchases and spending); in the current month a separate "+" button
# opens the logger.
class EnvelopeRowComponent < ApplicationComponent
  NEARLY_SPENT = 0.9

  def initialize(envelope:, budget_month:)
    @envelope     = envelope
    @budget_month = budget_month
    @budget       = budget_month.budget_for(envelope)
    @spent        = budget_month.spent_for(envelope)
  end

  def dom_id_for_row
    dom_id(@envelope, :row)
  end

  def loggable?
    @budget_month.current?
  end

  def budgeted?
    @budget.positive?
  end

  def remaining
    @budget - @spent
  end

  def over_budget?
    budgeted? && remaining.negative?
  end

  def status
    return :none unless budgeted?
    return :over if over_budget?
    return :low  if @spent >= @budget * NEARLY_SPENT
    :ok
  end

  def headline
    return "#{money(@spent)} spent" unless budgeted?
    over_budget? ? "#{money(remaining.abs)} over" : "#{money(remaining)} left"
  end

  def subline
    budgeted? ? "#{money(@spent)} spent" : "No budget set"
  end

  def headline_amount
    budgeted? ? money(remaining.abs) : money(@spent)
  end

  def headline_word
    return "spent" unless budgeted?
    "#{over_budget? ? "over" : "left"} of #{short_money(@budget)}"
  end

  def look
    @look ||= CategoryLook.for(@envelope)
  end

  def headline_class
    over_budget? ? "text-claret" : "text-ink"
  end

  def bar_percent
    return 0 unless budgeted?
    ((@spent / @budget) * 100).clamp(0, 100).round(1)
  end

  def bar_class
    { ok: "bg-sage", low: "bg-gilt", over: "bg-claret", none: "bg-line" }[status]
  end

  def ring_class
    { ok: "text-sage", low: "text-gilt", over: "text-claret", none: "text-line" }[status]
  end

  def accessible_label
    "Log a purchase in #{@envelope.name}. #{headline}"
  end

  def history_label
    detail = budgeted? ? "#{money(@spent)} spent of #{money(@budget)}" : subline
    "#{@envelope.name}: #{headline}, #{detail}. See purchases."
  end

  def logger_params
    {
      "logger-url-param":       helpers.envelope_expenses_path(@envelope),
      "logger-name-param":      @envelope.name,
      "logger-remaining-param": budgeted? ? remaining.to_f : ""
    }
  end

  def history_path
    helpers.envelope_expenses_path(@envelope, year: @budget_month.year, month: @budget_month.month)
  end

  private

  def money(value)
    helpers.number_to_currency(value)
  end

  # "$700" rather than "$700.00" where the cents add nothing.
  def short_money(value)
    helpers.number_to_currency(value, precision: (value % 1).zero? ? 0 : 2)
  end
end
