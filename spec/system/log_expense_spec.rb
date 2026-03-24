require "rails_helper"

RSpec.describe "Log expense journey", type: :system do
  let(:sally) { create(:user, email_address: "sally@test.com", password: "password123", password_confirmation: "password123") }
  let(:envelope) { create(:envelope, name: "Groceries", position: 1) }

  before do
    create(:envelope_budget, envelope: envelope, year: Date.current.year, month: Date.current.month, amount: 700)
    visit new_session_path
    fill_in "Email address", with: sally.email_address
    fill_in "Password", with: "password123"
    click_button "Sign in"
    expect(page).to have_current_path(root_path)
  end

  it "shows the dashboard after sign in" do
    expect(page).to have_current_path(root_path)
    expect(page).to have_text("Groceries")
  end

  it "Sally logs an expense and the balance updates without a full page reload" do
    # Confirm initial state
    expect(page).to have_text("$700.00")
    expect(page).to have_text("remaining")

    # Click Log expense on the Groceries card
    click_link "Log expense", match: :first

    # The expense form loads in the Turbo Frame
    expect(page).to have_text("Log Expense")
    expect(page).to have_text("Groceries")

    # Fill in the form
    find("#expense_amount").set("47.23")
    find("#expense_amount").send_keys(:return)

    # Balance updates in the card via Turbo Stream — no full page reload
    expect(page).to have_text("$652.77")
    expect(page).to have_text("remaining")
  end

  it "Sally cannot reach the settings page" do
    visit admin_settings_path
    expect(page).to have_current_path(root_path)
  end

  it "shows the correct month on the dashboard" do
    expect(page).to have_text("This Month")
    expect(page).to have_text(Date.current.strftime("%b"))
  end
end
