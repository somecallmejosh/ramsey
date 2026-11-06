class DebtPaymentsController < ApplicationController
  before_action :set_debt
  before_action :set_debt_payment, only: [ :destroy ]

  def new
    @debt_payment = @debt.debt_payments.build(paid_on: Date.current)
  end

  def create
    @debt_payment = @debt.debt_payments.build(debt_payment_params)
    @debt_payment.user = current_user

    if @debt_payment.save
      notice = "Payment logged. Balance is now #{helpers.number_to_currency(@debt.reload.current_balance)}."
      respond_to do |format|
        format.html { redirect_to debt_path(@debt), notice: notice }
        # The form lives in the "modal" frame, so a redirect would only swap that
        # frame and leave the balances behind it stale. Refresh the whole page
        # (debts list or debt detail, whichever the payment was logged from).
        format.turbo_stream do
          flash[:notice] = notice
          render turbo_stream: turbo_stream.refresh(request_id: nil)
        end
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    unless current_user.owner?
      redirect_to debt_path(@debt), alert: "Only the household owner can remove payments."
      return
    end

    @debt_payment.destroy!
    redirect_to debt_path(@debt),
                notice: "Removed the #{helpers.number_to_currency(@debt_payment.amount)} payment. " \
                        "Balance is now #{helpers.number_to_currency(@debt.reload.current_balance)}."
  end

  private

  def set_debt
    @debt = current_account.debts.find(params[:debt_id])
  end

  def set_debt_payment
    @debt_payment = @debt.debt_payments.find(params[:id])
  end

  def debt_payment_params
    params.require(:debt_payment).permit(:amount, :balance_after, :paid_on, :note)
  end
end
