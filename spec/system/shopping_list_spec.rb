require "rails_helper"

RSpec.describe "Shopping list management", type: :system do
  let(:sally) { create(:user, email_address: "sally@test.com", password: "password123", password_confirmation: "password123") }
  let!(:meal_plan) { create(:meal_plan, :confirmed, user: sally) }
  let!(:ground_beef) { create(:shopping_item, meal_plan: meal_plan, name: "Ground beef", quantity: "2 lbs", store: "Aldi", estimated_cost: 8.00) }
  let!(:pasta) { create(:shopping_item, meal_plan: meal_plan, name: "Pasta", quantity: "1 box", store: "Walmart", estimated_cost: 2.50) }

  before do
    visit new_session_path
    fill_in "Email address", with: sally.email_address
    fill_in "Password", with: "password123"
    click_button "Sign in"
    expect(page).to have_current_path(root_path)
    visit meal_plan_path(meal_plan)
  end

  it "Sally sees items grouped by store" do
    expect(page).to have_text("Aldi")
    expect(page).to have_text("Walmart")
    expect(page).to have_text("Ground beef")
    expect(page).to have_text("Pasta")

    # Aldi heading comes before Walmart heading
    aldi_pos    = page.body.index("Aldi")
    walmart_pos = page.body.index("Walmart")
    expect(aldi_pos).to be < walmart_pos
  end

  it "Sally adds a new shopping item and it appears in the list" do
    fill_in "new_item_name", with: "Olive oil"
    fill_in "new_item_quantity", with: "1 bottle"
    select "Walmart", from: "new_item_store"
    find("#new_item_cost").set("5.99")

    page.execute_script("document.getElementById('add-shopping-item-form').requestSubmit()")

    expect(page).to have_text("Olive oil", wait: 5)
    expect(page).to have_text("1 bottle")
    expect(ShoppingItem.find_by(name: "Olive oil")).to be_present
  end

  it "Sally cannot add an item without a name" do
    # Chrome 146 headless: button click doesn't trigger Turbo form submission
    # when no form field was previously interacted with. Use requestSubmit() instead.
    page.execute_script("document.getElementById('add-shopping-item-form').requestSubmit()")

    expect(page).to have_text("Name can't be blank", wait: 5)
    expect(ShoppingItem.count).to eq(2)
  end

  it "Sally removes a shopping item and it disappears from the list" do
    expect(page).to have_text("Ground beef")

    find("button[aria-label='Remove Ground beef']").click

    expect(page).not_to have_text("Ground beef", wait: 5)
    expect(ShoppingItem.find_by(name: "Ground beef")).to be_nil
  end
end
