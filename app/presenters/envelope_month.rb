# One category's month: what was budgeted, every purchase, and spending by
# week. Backs the category history page and its Turbo Stream refreshes.
class EnvelopeMonth
  Week = Data.define(:starts_on, :ends_on, :spent) do
    def label
      if starts_on.month == ends_on.month
        "#{starts_on.strftime("%b %-d")}–#{ends_on.day}"
      else
        "#{starts_on.strftime("%b %-d")}–#{ends_on.strftime("%b %-d")}"
      end
    end
  end

  attr_reader :envelope, :date

  def initialize(envelope, date = Date.current)
    @envelope = envelope
    @date     = date.beginning_of_month
  end

  def current? = date == Date.current.beginning_of_month

  def expenses
    @expenses ||= envelope.expenses
      .where(transacted_on: date.all_month)
      .includes(:user)
      .order(transacted_on: :desc, created_at: :desc)
      .to_a
  end

  def budget
    return @budget if defined?(@budget)
    @budget = EnvelopeBudget.find_by(envelope: envelope, year: date.year, month: date.month)&.amount
  end

  def spent = expenses.sum(&:amount)
  def left  = budget.to_d - spent

  # Spending an even amount each week would land exactly on budget.
  def weekly_pace
    return unless budget&.positive?
    (budget * 7 / date.end_of_month.day).round(2)
  end

  # Calendar weeks (Sun–Sat) clipped to this month.
  def weeks
    @weeks ||= begin
      by_day = expenses.group_by(&:transacted_on)
      first, last = date, date.end_of_month
      first.beginning_of_week(:sunday).step(last, 7).map do |sunday|
        starts_on = [ sunday, first ].max
        ends_on   = [ sunday + 6, last ].min
        Week.new(starts_on:, ends_on:, spent: (starts_on..ends_on).sum { |d| by_day.fetch(d, []).sum(&:amount) })
      end
    end
  end

  def busiest_week_spent = weeks.map(&:spent).max.to_d
end
