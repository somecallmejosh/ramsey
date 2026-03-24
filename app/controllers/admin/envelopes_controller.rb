module Admin
  class EnvelopesController < ApplicationController
    include RequireAdmin

    before_action :require_admin_role
    before_action :set_envelope, only: [ :deactivate, :reactivate ]

    def deactivate
      @envelope.update!(active: false)
      redirect_to admin_settings_path, notice: "#{@envelope.name} deactivated."
    end

    def reactivate
      @envelope.update!(active: true)
      redirect_to admin_settings_path, notice: "#{@envelope.name} reactivated."
    end

    private

    def set_envelope
      @envelope = Envelope.find(params[:id])
    end
  end
end
