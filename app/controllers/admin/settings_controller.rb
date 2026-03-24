module Admin
  class SettingsController < ApplicationController
    include RequireAdmin

    before_action :require_admin_role

    def show
      @envelopes = Envelope.ordered
      @budgets   = EnvelopeBudget
        .where(envelope_id: @envelopes.select(:id), year: Date.current.year, month: Date.current.month)
        .index_by(&:envelope_id)
    end
  end
end
