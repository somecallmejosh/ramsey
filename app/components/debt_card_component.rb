class DebtCardComponent < ApplicationComponent
  def initialize(debt:, current_user:, snowball_target: false)
    @debt = debt
    @current_user = current_user
    @snowball_target = snowball_target
  end

  def snowball_target? = @snowball_target
  def admin? = @current_user.admin?
  def paid_off? = @debt.paid_off?

  def type_label
    @debt.debt_type.humanize.titleize
  end

  def progress_bar_width
    "#{@debt.progress_pct}%"
  end
end
