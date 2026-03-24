class PageHeadingComponent < ApplicationComponent
  def initialize(current_user:, selected_date:)
    @current_user  = current_user
    @selected_date = selected_date
  end

  def greeting
    hour = Time.current.hour
    if hour < 12 then "Good morning"
    elsif hour < 17 then "Good afternoon"
    else "Good evening"
    end
  end

  def first_name
    @current_user.email_address.split("@").first.capitalize
  end

  def month_label
    if @selected_date.year == Date.current.year && @selected_date.month == Date.current.month
      "This Month"
    else
      @selected_date.strftime("%B %Y")
    end
  end
end
