require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  let(:account)  { create(:account) }
  let(:member)   { create(:user, account: account) }
  let!(:envelope) { create(:envelope, account: account, name: "Groceries") }

  before { sign_in(member) }

  it "renders the logger for the current month" do
    get root_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("to log a purchase. Tap a category to see its spending.")
    expect(response.body).to include("logger-sheet")
  end

  it "shows a past month read-only" do
    last = Date.current.last_month
    get dashboard_path(year: last.year, month: last.month)
    expect(response.body).to include("past month")
    expect(response.body).not_to include("logger-sheet")
  end

  it "treats a future month as this month" do
    nxt = Date.current.next_month
    get dashboard_path(year: nxt.year, month: nxt.month)
    expect(response.body).to include("to log a purchase. Tap a category to see its spending.")
  end
end
