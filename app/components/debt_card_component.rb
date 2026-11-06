class DebtCardComponent < ApplicationComponent
  def initialize(debt:, current_user:, snowball_target: false, can_move_up: false, can_move_down: false)
    @debt = debt
    @current_user = current_user
    @snowball_target = snowball_target
    @can_move_up = can_move_up
    @can_move_down = can_move_down
  end

  def snowball_target? = @snowball_target
  def owner? = @current_user.owner?
  def paid_off? = @debt.paid_off?
  def reorderable? = owner? && (@can_move_up || @can_move_down)

  def type_label
    @debt.debt_type.humanize.titleize
  end

  def apr_label
    return if @debt.interest_rate.blank?

    "#{number_to_percentage(@debt.interest_rate, precision: 3, strip_insignificant_zeros: true)} APR"
  end

  def icon_name
    case "#{@debt.debt_type} #{@debt.name}".downcase
    when /credit|card/ then "credit-card"
    when /car|auto/    then "car-simple"
    when /student/     then "graduation-cap"
    when /medical/     then "first-aid"
    when /mortgage|home/ then "house-line"
    else "receipt"
    end
  end

  def progress_bar_width
    "#{@debt.progress_pct}%"
  end
end
