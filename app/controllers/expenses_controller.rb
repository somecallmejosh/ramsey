class ExpensesController < ApplicationController
  before_action :set_envelope
  before_action :set_expense, only: [:destroy]

  def new
    @expense = @envelope.expenses.build(transacted_on: Date.current)
  end

  def create
    @expense = @envelope.expenses.build(expense_params)
    @expense.user = current_user

    if @expense.save
      respond_to do |format|
        format.html { redirect_to root_path, notice: "Expense logged." }
        format.turbo_stream
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    if can_delete?
      @expense.destroy
      respond_to do |format|
        format.html { redirect_to root_path, notice: "Expense deleted." }
        format.turbo_stream
      end
    else
      redirect_to root_path, alert: "Not authorized."
    end
  end

  private

  def set_envelope
    @envelope = Envelope.find(params[:envelope_id])
  end

  def set_expense
    @expense = @envelope.expenses.find(params[:id])
  end

  def expense_params
    params.require(:expense).permit(:amount, :note, :transacted_on)
  end

  def can_delete?
    return true if current_user.admin?
    !@expense.prior_month?
  end
end
