module ApplicationHelper
  include UiHelper
  include IconHelper

  # "Today", "Yesterday", "Mon", or "Oct 3" — how people talk about recent dates.
  def friendly_day(date)
    today = Date.current
    return "Today" if date == today
    return "Yesterday" if date == today - 1
    return date.strftime("%A") if date > today - 7
    date.strftime("%b %-d")
  end

  # What's left in the current household's Groceries envelope this month.
  # Used by the meal planner to keep the shopping list within budget.
  def current_groceries_remaining
    month     = BudgetMonth.new(current_account)
    groceries = month.envelopes.find { |envelope| envelope.name == "Groceries" }
    return 0 unless groceries

    month.budget_for(groceries) - month.spent_for(groceries)
  end

  def greeting(now = Time.current)
    case now.hour
    when 5...12  then "Good morning"
    when 12...17 then "Good afternoon"
    else "Good evening"
    end
  end

  # "$1,234.56" with the cents set small, for headline numbers.
  def money_with_cents(amount)
    whole, cents = number_to_currency(amount.to_d.abs).split(".")
    safe_join([ whole, tag.span(".#{cents}", class: "cents") ])
  end
end
