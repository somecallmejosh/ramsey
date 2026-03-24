require "rails_helper"

RSpec.describe "MealPlans", type: :request do
  let(:user) { create(:user) }

  let(:api_stub_body) do
    {
      content: [{
        type: "text",
        text: {
          meals: [
            { day_of_week: 0, dinner: "Roast Chicken", lunch: "Chicken Salad",
              prep_note: nil, estimated_cost: 14.00 },
            { day_of_week: 1, dinner: "Stir Fry",      lunch: "Leftovers",
              prep_note: nil, estimated_cost: 8.00 },
            { day_of_week: 2, dinner: "Pasta",          lunch: "Sandwiches",
              prep_note: nil, estimated_cost: 6.00 },
            { day_of_week: 3, dinner: "Tacos",          lunch: "Leftovers",
              prep_note: nil, estimated_cost: 10.00 },
            { day_of_week: 4, dinner: "Soup",           lunch: "Sandwiches",
              prep_note: nil, estimated_cost: 7.00 },
            { day_of_week: 5, dinner: "Pizza",          lunch: "Leftovers",
              prep_note: nil, estimated_cost: 12.00 },
            { day_of_week: 6, dinner: "Burgers",        lunch: "Salad",
              prep_note: nil, estimated_cost: 9.00 }
          ],
          shopping_items: [
            { name: "Ground beef", quantity: "2 lbs", estimated_cost: 8.00, store: "Aldi" }
          ]
        }.to_json
      }]
    }.to_json
  end

  before do
    stub_request(:post, "https://api.anthropic.com/v1/messages")
      .to_return(status: 200,
                 headers: { "Content-Type" => "application/json" },
                 body: api_stub_body)
    sign_in(user)
  end

  describe "GET /meal_plans/new" do
    it "returns 200" do
      get new_meal_plan_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /meal_plans" do
    it "creates a MealPlan and redirects to preview" do
      expect {
        post meal_plans_path, params: { message: "Keep it simple this week." }
      }.to change(MealPlan, :count).by(1)

      expect(response).to redirect_to(meal_plan_path(MealPlan.last))
      expect(MealPlan.last.ai_response).to be_present
    end

    it "destroys an existing unconfirmed plan for the same week before creating" do
      existing = create(:meal_plan, user: user)
      expect {
        post meal_plans_path, params: { message: "Keep it simple." }
      }.not_to change(MealPlan, :count)

      expect { existing.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect(MealPlan.last.ai_response).to be_present
    end
  end

  describe "GET /meal_plans/:id" do
    context "unconfirmed plan (preview)" do
      let(:plan) { create(:meal_plan, user: user, ai_response: { "meals" => [], "shopping_items" => [] }) }

      it "returns 200" do
        get meal_plan_path(plan)
        expect(response).to have_http_status(:ok)
      end
    end

    context "confirmed plan" do
      let(:plan) { create(:meal_plan, :confirmed, user: user) }

      it "returns 200" do
        get meal_plan_path(plan)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "PATCH /meal_plans/:id/confirm" do
    let(:plan) do
      create(:meal_plan, user: user, ai_response: {
        "meals" => [
          { "day_of_week" => 0, "dinner" => "Pasta", "lunch" => "Leftovers",
            "prep_note" => nil, "estimated_cost" => 6.00 }
        ],
        "shopping_items" => [
          { "name" => "Pasta", "quantity" => "1 box", "estimated_cost" => 1.50, "store" => "Aldi" }
        ]
      })
    end

    it "creates Meal and ShoppingItem records and sets confirmed_at" do
      expect {
        patch confirm_meal_plan_path(plan)
      }.to change(Meal, :count).by(1).and change(ShoppingItem, :count).by(1)

      expect(plan.reload.confirmed?).to be true
      expect(response).to redirect_to(meal_plan_path(plan))
    end
  end

  describe "unauthenticated access" do
    before { delete session_path }

    it "redirects to sign in" do
      get new_meal_plan_path
      expect(response).to redirect_to(new_session_path)
    end
  end
end
