require "rails_helper"

RSpec.describe "Log a purchase", type: :system do
  let(:account)  { create(:account) }
  let(:sally)    { create(:user, account: account, email_address: "sally@test.com", password: "password123", password_confirmation: "password123") }
  let!(:envelope) { create(:envelope, account: account, name: "Groceries", position: 1) }

  before do
    create(:envelope_budget, envelope: envelope, year: Date.current.year, month: Date.current.month, amount: 700)
    visit new_session_path
    fill_in "Email address", with: sally.email_address
    fill_in "Password", with: "password123"
    click_button "Sign in"
    expect(page).to have_current_path(root_path)
  end

  it "takes three taps: category, amount, Save — and can be undone" do
    expect(page).to have_css("#row_envelope_#{envelope.id}", text: /\$700.00\s+left/)

    find("button[aria-label^='Log a purchase in Groceries']").click
    within("dialog[open]") do
      expect(page).to have_text("Groceries")
      %w[4 7 . 2 3].each { |key| tap_key(key) }
      expect(page).to have_text("$652.77 left after this")
      find_button("Save $47.23").click
    end

    expect(page).to have_no_css("dialog[open]")
    expect(page).to have_text("Saved $47.23 to Groceries")
    expect(page).to have_css("#row_envelope_#{envelope.id}", text: /\$652.77\s+left/)
    within("#recent-expenses") { expect(page).to have_text("$47.23") }

    find_button("Undo").click
    expect(page).to have_text("Removed $47.23 from Groceries")
    expect(page).to have_css("#row_envelope_#{envelope.id}", text: /\$700.00\s+left/)
    expect(Expense.count).to eq(0)
  end

  it "accepts typing on a keyboard" do
    find("button[aria-label^='Log a purchase in Groceries']").click
    # Dispatch real keydown events at the sheet: headless Chrome 146 sometimes
    # loses WebDriver keystrokes (see spec/support/capybara.rb).
    press_keys find("dialog[open]"), *"12.5".chars, "Enter"
    expect(page).to have_text("Saved $12.50 to Groceries")
  end

  def press_keys(element, *keys)
    keys.each do |key|
      page.execute_script(<<~JS, element, key)
        arguments[0].dispatchEvent(new KeyboardEvent("keydown", { key: arguments[1], bubbles: true, cancelable: true }))
      JS
    end
  end

  def tap_key(key)
    find(%([data-logger-key-param="#{key}"])).click
  end

  it "Sally cannot reach the settings page" do
    visit admin_settings_path
    expect(page).to have_current_path(root_path)
  end

  it "shows the current month, labelled, with no way forward into the future" do
    within("nav[aria-label='Choose month']") do
      expect(page).to have_text(Date.current.strftime("%B %Y"))
      expect(page).to have_text("This month")
      expect(page).to have_link(href: dashboard_path(year: Date.current.prev_month.year, month: Date.current.prev_month.month))
      expect(page).to have_css("[aria-disabled='true']", text: Date.current.next_month.strftime("%b"))
    end
  end
end
