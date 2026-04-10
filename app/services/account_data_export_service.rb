require "csv"

class AccountDataExportService
  Result = Data.define(:success, :csv, :error) do
    def success? = success
  end

  def initialize(account:)
    @account = account
  end

  def call
    csv = CSV.generate do |rows|
      export_users(rows)
      export_envelopes(rows)
      export_envelope_budgets(rows)
      export_expenses(rows)
      export_debts(rows)
      export_debt_payments(rows)
      export_meal_plans(rows)
      export_meals(rows)
      export_shopping_items(rows)
      export_lunch_logs(rows)
    end

    Result.new(success: true, csv: csv, error: nil)
  rescue StandardError => e
    Result.new(success: false, csv: nil, error: e.message)
  end

  private

  def section_header(rows, title, columns)
    rows << []
    rows << [ title ]
    rows << columns
  end

  def export_users(rows)
    section_header(rows, "Users", %w[Email Role Created])
    @account.users.find_each do |user|
      rows << [ user.email_address, user.role, user.created_at ]
    end
  end

  def export_envelopes(rows)
    section_header(rows, "Envelopes", %w[Name Active])
    @account.envelopes.find_each do |env|
      rows << [ env.name, env.active ]
    end
  end

  def export_envelope_budgets(rows)
    section_header(rows, "Envelope Budgets", %w[Envelope Year Month Amount])
    @account.envelope_budgets.includes(:envelope).find_each do |budget|
      rows << [ budget.envelope.name, budget.year, budget.month, budget.amount.to_f ]
    end
  end

  def export_expenses(rows)
    section_header(rows, "Expenses", %w[Envelope User Amount Note Date])
    @account.expenses.includes(:envelope, :user).find_each do |expense|
      rows << [ expense.envelope.name, expense.user.email_address, expense.amount.to_f,
               expense.note, expense.transacted_on ]
    end
  end

  def export_debts(rows)
    section_header(rows, "Debts", %w[Name Type OriginalBalance CurrentBalance MinimumPayment InterestRate PaidOffAt])
    @account.debts.find_each do |debt|
      rows << [ debt.name, debt.debt_type, debt.original_balance.to_f, debt.current_balance.to_f,
               debt.minimum_payment.to_f, debt.interest_rate&.to_f, debt.paid_off_at ]
    end
  end

  def export_debt_payments(rows)
    section_header(rows, "Debt Payments", %w[Debt User Amount BalanceAfter PaidOn Note])
    @account.debt_payments.includes(:debt, :user).find_each do |payment|
      rows << [ payment.debt.name, payment.user.email_address, payment.amount.to_f,
               payment.balance_after.to_f, payment.paid_on, payment.note ]
    end
  end

  def export_meal_plans(rows)
    section_header(rows, "Meal Plans", %w[WeekStart Status ConfirmedAt])
    @account.meal_plans.find_each do |plan|
      rows << [ plan.week_start, plan.status, plan.confirmed_at ]
    end
  end

  def export_meals(rows)
    section_header(rows, "Meals", %w[WeekStart DayOfWeek Lunch Dinner PrepNote EstimatedCost])
    Meal.joins(:meal_plan).where(meal_plans: { account_id: @account.id }).find_each do |meal|
      rows << [ meal.meal_plan.week_start, meal.day_of_week, meal.lunch, meal.dinner,
               meal.prep_note, meal.estimated_cost&.to_f ]
    end
  end

  def export_shopping_items(rows)
    section_header(rows, "Shopping Items", %w[WeekStart Name Quantity Store EstimatedCost])
    ShoppingItem.joins(:meal_plan).where(meal_plans: { account_id: @account.id }).find_each do |item|
      rows << [ item.meal_plan.week_start, item.name, item.quantity, item.store,
               item.estimated_cost&.to_f ]
    end
  end

  def export_lunch_logs(rows)
    section_header(rows, "Lunch Logs", %w[User Date])
    LunchLog.joins(:user).where(users: { account_id: @account.id }).find_each do |log|
      rows << [ log.user.email_address, log.logged_on ]
    end
  end
end
