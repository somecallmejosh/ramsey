class DebtPaymentsController < ApplicationController
  before_action :set_debt
  before_action :set_debt_payment, only: [ :destroy ]

  def new
    @debt_payment = @debt.debt_payments.build(
      paid_on: Date.current,
      balance_after: @debt.current_balance
    )
  end

  def create
    @debt_payment = @debt.debt_payments.build(debt_payment_params)
    @debt_payment.user = current_user

    if @debt_payment.save
      redirect_to debt_path(@debt), notice: "Payment logged."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    unless current_user.admin?
      redirect_to debt_path(@debt), alert: "Not authorized."
      return
    end

    @debt_payment.destroy
    redirect_to debt_path(@debt), notice: "Payment removed."
  end

  private

  def set_debt
    @debt = Debt.find(params[:debt_id])
  end

  def set_debt_payment
    @debt_payment = @debt.debt_payments.find(params[:id])
  end

  def debt_payment_params
    params.require(:debt_payment).permit(:amount, :balance_after, :paid_on, :note)
  end
end
