require "rails_helper"

RSpec.describe ExpenseRowComponent, type: :component do
  let(:envelope) { create(:envelope) }
  let(:admin)    { create(:user, :admin) }
  let(:standard) { create(:user) }

  it "shows delete control for admin on prior month expense" do
    expense = create(:expense, :prior_month, envelope: envelope, user: standard)
    result  = render_inline(ExpenseRowComponent.new(expense: expense, current_user: admin))
    expect(result.to_html).to include("Delete expense")
  end

  it "hides delete control for standard user on prior month expense" do
    expense = create(:expense, :prior_month, envelope: envelope, user: standard)
    result  = render_inline(ExpenseRowComponent.new(expense: expense, current_user: standard))
    expect(result.to_html).not_to include("Delete expense")
  end

  it "shows delete control for standard user on current month expense" do
    expense = create(:expense, envelope: envelope, user: standard)
    result  = render_inline(ExpenseRowComponent.new(expense: expense, current_user: standard))
    expect(result.to_html).to include("Delete expense")
  end

  it "displays the expense amount" do
    expense = create(:expense, envelope: envelope, user: standard, amount: 47.23)
    result  = render_inline(ExpenseRowComponent.new(expense: expense, current_user: standard))
    expect(result.text).to include("$47.23")
  end
end
