module Admin
  class DebtsController < ApplicationController
    include RequireOwner

    before_action :require_owner_role
    before_action :set_debt, only: [ :edit, :update ]

    def new
      @debt = current_account.debts.build
    end

    def create
      @debt = current_account.debts.build(debt_params)
      @debt.position = current_account.debts.maximum(:position).to_i + 1

      if @debt.save
        redirect_to debts_path, notice: "Debt added."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @debt.update(debt_params)
        redirect_to debts_path, notice: "Debt updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_debt
      @debt = current_account.debts.find(params[:id])
    end

    def debt_params
      params.require(:debt).permit(
        :name, :debt_type, :original_balance, :current_balance,
        :minimum_payment, :interest_rate, :position
      )
    end
  end
end
