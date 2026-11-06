class ExpensesController < ApplicationController
  before_action :set_envelope
  before_action :set_expense, only: [ :destroy ]

  def index
    @envelope_month = EnvelopeMonth.new(@envelope, requested_month)
  end

  def new
    @expense = @envelope.expenses.build(transacted_on: Date.current)
  end

  def create
    @expense = @envelope.expenses.build(expense_params)
    @expense.user = current_user

    if @expense.save
      respond_to do |format|
        format.html { redirect_to root_path, notice: "Saved #{helpers.number_to_currency(@expense.amount)} to #{@envelope.name}." }
        format.turbo_stream { @budget_month = BudgetMonth.new(current_account) }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream { render :create_failed, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    unless can_delete?
      return redirect_to envelope_expenses_path(@envelope),
        alert: "Only the household owner can remove purchases from past months."
    end

    @expense.destroy
    respond_to do |format|
      format.html do
        redirect_to envelope_expenses_path(@envelope, year: @expense.transacted_on.year, month: @expense.transacted_on.month),
          notice: "Removed #{helpers.number_to_currency(@expense.amount)} from #{@envelope.name}."
      end
      format.turbo_stream { refresh_for(@expense) }
    end
  end

  # Undo for a delete: puts the purchase back exactly as it was.
  def restore
    @expense = Expense.restore_from(params[:token], envelope: @envelope)

    if @expense&.persisted?
      respond_to do |format|
        format.html { redirect_to envelope_expenses_path(@envelope), notice: "Put back #{helpers.number_to_currency(@expense.amount)}." }
        format.turbo_stream { refresh_for(@expense) }
      end
    else
      redirect_to envelope_expenses_path(@envelope), alert: "That purchase can't be put back any more. Log it again if you still need it."
    end
  end

  private

  def set_envelope
    @envelope = current_account.envelopes.find(params[:envelope_id])
  end

  def set_expense
    @expense = @envelope.expenses.find(params[:id])
  end

  def expense_params
    params.require(:expense).permit(:amount, :note, :transacted_on)
  end

  def requested_month
    return Date.current unless params[:year] && params[:month]

    date = Date.new(params[:year].to_i, params[:month].to_i.clamp(1, 12))
    date > Date.current ? Date.current : date
  rescue Date::Error
    Date.current
  end

  def refresh_for(expense)
    @budget_month   = BudgetMonth.new(current_account)
    @envelope_month = EnvelopeMonth.new(@envelope, expense.transacted_on)
  end

  def can_delete?
    @expense.deletable_by?(current_user)
  end
end
