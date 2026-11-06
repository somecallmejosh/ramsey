# What the household hears about one logged purchase.
#
# Everyone else in the account gets "Josh logged $47.23 to Groceries". When
# that purchase is the one that pushes the category into "nearly spent" or
# "over", the message says so, and the person who logged it gets the alert too.
#
# "Crossing" is measured in logging order (expense id), so a category that is
# already over doesn't re-alert on every purchase, and two purchases logged
# seconds apart each see the balance as it was when they were logged.
class ExpenseNotification
  include ActiveSupport::NumberHelper

  NEARLY_SPENT = EnvelopeRowComponent::NEARLY_SPENT

  def initialize(expense)
    @expense  = expense
    @envelope = expense.envelope
    @month    = expense.transacted_on.beginning_of_month
  end

  # Payload for the other members of the household.
  def for_household
    title = case crossed
    when :over then "#{@envelope.name} is over budget"
    when :low  then "#{@envelope.name} is nearly spent"
    else "#{logger_name} logged #{money(@expense.amount)} to #{@envelope.name}"
    end
    body = crossed ? "#{logger_name} logged #{money(@expense.amount)}. #{balance_line}" : balance_line

    payload(title, body)
  end

  # Payload for the person who logged it: only when it crossed a threshold.
  def for_logger
    return unless crossed

    title = crossed == :over ? "#{@envelope.name} is over budget" : "#{@envelope.name} is nearly spent"
    payload(title, "You logged #{money(@expense.amount)}. #{balance_line}")
  end

  # :low or :over when this purchase moved the category into that state,
  # otherwise nil. Only for this month's budgeted categories: a backdated
  # purchase into a closed month isn't something anyone can act on.
  def crossed
    return @crossed if defined?(@crossed)

    after   = status(spent_through)
    before  = status(spent_through - @expense.amount)
    current = @month == Date.current.beginning_of_month
    @crossed = (current && budget.positive? && after != before && after != :ok) ? after : nil
  end

  private

  def payload(title, body)
    {
      title: title,
      body:  body,
      url:   Rails.application.routes.url_helpers.envelope_expenses_path(
               @envelope, year: @month.year, month: @month.month
             )
    }
  end

  def balance_line
    when_said = @month == Date.current.beginning_of_month ? "this month" : "for #{@month.strftime("%B")}"
    return "#{money(spent_through)} spent #{when_said}." unless budget.positive?

    remaining = budget - spent_through
    if remaining.negative?
      "#{money(remaining.abs)} over the #{money(budget)} budget #{when_said}."
    else
      "#{money(remaining)} left of #{money(budget)} #{when_said}."
    end
  end

  def status(spent)
    return :over if spent > budget
    return :low  if spent >= budget * NEARLY_SPENT
    :ok
  end

  def spent_through
    @spent_through ||= @envelope.expenses
      .for_month(@month.year, @month.month)
      .where(id: ..@expense.id)
      .sum(:amount)
  end

  def budget
    @budget ||= @envelope.budget_for(year: @month.year, month: @month.month).to_d
  end

  def logger_name
    @expense.user.display_name
  end

  def money(amount)
    number_to_currency(amount)
  end
end
