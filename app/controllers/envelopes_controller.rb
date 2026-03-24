class EnvelopesController < ApplicationController
  include RequireAdmin

  before_action :require_admin_role, only: [:new, :create, :edit, :update]
  before_action :set_envelope, only: [:edit, :update]

  def new
    @envelope        = Envelope.new
    @envelope_budget = @envelope.envelope_budgets.build(
      year: Date.current.year, month: Date.current.month
    )
  end

  def create
    @envelope = Envelope.new(envelope_params)
    @envelope.position = Envelope.maximum(:position).to_i + 1

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
    @envelope = Envelope.find(params[:id])
  end

  def envelope_params
    params.require(:envelope).permit(:name, :active)
  end
end
