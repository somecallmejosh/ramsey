class WeeklySpendQuery
  def initialize(envelope)
    @envelope = envelope
  end

  def for_month(year, month)
    start_date = Date.new(year, month, 1)
    end_date = start_date.end_of_month

    spend = @envelope.expenses
      .where(transacted_on: start_date..end_date)
      .group_by_week(:transacted_on, week_start: :sunday, time_zone: false)
      .sum(:amount)

    all_weeks = {}
    week = start_date.beginning_of_week(:sunday)
    while week <= end_date
      week_end = week + 6.days
      label = "#{week.strftime("%-m/%d")}-#{week_end.strftime("%-m/%d")}"
      all_weeks[label] = spend.fetch(week, 0)
      week += 7.days
    end

    all_weeks
  end
end
