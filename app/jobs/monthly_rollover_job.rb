class MonthlyRolloverJob < ApplicationJob
  queue_as :default

  def perform
    today      = Date.current
    year       = today.year
    month      = today.month
    last_month = today.last_month

    records = EnvelopeBudget
      .where(year: last_month.year, month: last_month.month)
      .joins(:envelope)
      .merge(Envelope.where(active: true))
      .map do |eb|
        { envelope_id: eb.envelope_id, year: year, month: month,
          amount: eb.amount, created_at: Time.current, updated_at: Time.current }
      end

    EnvelopeBudget.upsert_all(records, unique_by: [:envelope_id, :year, :month]) if records.any?
  end
end
