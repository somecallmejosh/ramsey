class EnvelopesController < ApplicationController
  include RequireOwner

  before_action :require_owner_role, only: [ :new, :create, :edit, :update ]
  before_action :set_envelope, only: [ :edit, :update ]

  def new
    @envelope        = current_account.envelopes.build
    @envelope_budget = @envelope.envelope_budgets.build(
      year: Date.current.year, month: Date.current.month
    )
  end

  def create
    @envelope = current_account.envelopes.build(envelope_params)
    @envelope.position = current_account.envelopes.maximum(:position).to_i + 1

    Envelope.transaction do
      @envelope.save!
      @envelope.envelope_budgets.create!(
        year: Date.current.year, month: Date.current.month,
        amount: params[:envelope_budget_amount].to_d
      )
    end

    redirect_to admin_settings_path, notice: "Envelope created."
  rescue ActiveRecord::RecordInvalid => e
    @envelope_budget = @envelope.envelope_budgets.build
    flash.now[:alert] = e.message
    render :new, status: :unprocessable_entity
  end

  def edit
    @envelope_budget = @envelope.envelope_budgets.find_by(
      year: Date.current.year, month: Date.current.month
    ) || @envelope.envelope_budgets.build(year: Date.current.year, month: Date.current.month)
  end

  def update
    if @envelope.update(envelope_params)
      redirect_to admin_settings_path, notice: "Envelope updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_envelope
    @envelope = current_account.envelopes.find(params[:id])
  end

  def envelope_params
    params.require(:envelope).permit(:name, :active)
  end
end
