class EnvelopeBudgetsController < ApplicationController
  include RequireAdmin

  before_action :require_admin_role, only: [ :update ]
  before_action :set_envelope_budget

  def edit
  end

  def update
    if @envelope_budget.update(envelope_budget_params)
      redirect_to admin_settings_path, notice: "Budget updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_envelope_budget
    @envelope_budget = EnvelopeBudget.find(params[:id])
  end

  def envelope_budget_params
    params.require(:envelope_budget).permit(:amount)
  end
end
