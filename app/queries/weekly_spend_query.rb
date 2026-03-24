class WeeklySpendQuery
  WEEKS_BACK = 8

  def initialize(envelope)
    @envelope = envelope
  end

  def past_eight_weeks
    @envelope.expenses
      .group_by_week(:transacted_on, last: WEEKS_BACK, week_start: :sunday, time_zone: false)
      .sum(:amount)
  end
end
