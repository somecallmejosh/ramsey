module Admin
  class SettingsController < ApplicationController
    include RequireAdmin

    before_action :require_admin_role

    def show
      load_envelopes_and_budgets
    end

    def update
      year  = Date.current.year
      month = Date.current.month
      now   = Time.current

      budget_params = params.permit(budgets: {}).fetch(:budgets, {})

      records = budget_params.filter_map do |envelope_id, amount|
        next unless Envelope.exists?(id: envelope_id, active: true)

        { envelope_id: envelope_id.to_i,
          year:        year,
          month:       month,
          amount:      amount.to_f.abs,
          created_at:  now,
          updated_at:  now }
      end

      if records.any?
        EnvelopeBudget.upsert_all(records, unique_by: [:envelope_id, :year, :month])
      end

      redirect_to admin_settings_path, notice: "Budgets saved."
    end

    private

    def load_envelopes_and_budgets
      @envelopes = Envelope.ordered
      @budgets   = EnvelopeBudget
        .where(envelope_id: @envelopes.select(:id), year: Date.current.year, month: Date.current.month)
        .index_by(&:envelope_id)
    end
  end
end
