module LunchLogsHelper
  # Returns an array of weeks, each week being an array of 5 Dates (Mon–Fri),
  # covering all weekdays that fall within the given month.
  def weeks_for_month(year, month)
    start_date = Date.new(year, month, 1)
    end_date   = start_date.end_of_month
    week_start = start_date.beginning_of_week(:monday)
    weeks = []
    current = week_start
    while current <= end_date
      weeks << (0..4).map { |d| current + d }
      current += 7.days
    end
    weeks
  end
end
