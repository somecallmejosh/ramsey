require "rails_helper"

RSpec.describe "Meal plan chat journey", type: :system do
  let(:account) { create(:account) }
  let(:sally) { create(:user, account: account, email_address: "sally@test.com", password: "password123", password_confirmation: "password123") }

  let(:ai_response) do
    {
      "meals" => [
        { "day_of_week" => 0, "dinner" => "Roast Chicken", "lunch" => "Chicken Salad",
          "prep_note" => "Season the night before", "estimated_cost" => 14.00 },
        { "day_of_week" => 1, "dinner" => "Stir Fry",     "lunch" => "Leftovers",     "prep_note" => nil, "estimated_cost" => 8.00 },
        { "day_of_week" => 2, "dinner" => "Pasta",         "lunch" => "Sandwiches",   "prep_note" => nil, "estimated_cost" => 6.00 },
        { "day_of_week" => 3, "dinner" => "Tacos",         "lunch" => "Leftovers",    "prep_note" => nil, "estimated_cost" => 10.00 },
        { "day_of_week" => 4, "dinner" => "Soup",          "lunch" => "Sandwiches",   "prep_note" => "Freeze half", "estimated_cost" => 7.00 },
        { "day_of_week" => 5, "dinner" => "Pizza",         "lunch" => "Leftovers",    "prep_note" => nil, "estimated_cost" => 12.00 },
        { "day_of_week" => 6, "dinner" => "Burgers",       "lunch" => "Salad",        "prep_note" => nil, "estimated_cost" => 9.00 }
      ],
      "shopping_items" => [
        { "name" => "Ground beef", "quantity" => "2 lbs", "estimated_cost" => 8.00, "store" => "Aldi" }
      ]
    }
  end

  before do
    visit new_session_path
    fill_in "Email address", with: sally.email_address
    fill_in "Password", with: "password123"
    click_button "Sign in"
    expect(page).to have_current_path(root_path)
  end

  it "Sally sees the meal planner nav link" do
    expect(page).to have_link("Meals")
  end

  it "Sally views the chat form" do
    click_link "Meals"
    expect(page).to have_text("Meal Planner")
    expect(page).to have_field("What are you working with this week?")
    expect(page).to have_button("Generate meal plan")
  end

  context "with an AI-generated preview already stored" do
    let!(:draft_plan) do
      create(:meal_plan, user: sally, ai_response: ai_response)
    end

    it "Sally reviews the preview, edits a dinner, and confirms it" do
      visit meal_plan_path(draft_plan)

      # Preview is visible with editable fields
      expect(page).to have_text("Review Your Plan")
      expect(page).to have_field("meals[0][dinner]", with: "Roast Chicken")

      # Edit one dinner
      find("input[name='meals[0][dinner]']").set("Lemon Herb Chicken")

      # Confirm the plan
      click_button "Confirm plan"

      # Confirmed plan view shows the updated meal
      expect(page).to have_text("This Week")
      expect(page).to have_text("Lemon Herb Chicken")
      expect(page).to have_text("Ground beef")
    end

    it "Sally confirms a plan and can check off a shopping item" do
      visit meal_plan_path(draft_plan)
      click_button "Confirm plan"

      # Confirmed view: shopping list is present
      expect(page).to have_text("Ground beef")

      item = ShoppingItem.last
      check "item_#{item.id}"

      # Turbo Stream updates the row — label gets line-through
      expect(page).to have_css("label.line-through", wait: 5)
    end
  end
end
