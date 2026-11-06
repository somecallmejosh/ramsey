require "rails_helper"

RSpec.describe "MealPlans", type: :request do
  let(:user) { create(:user) }

  let(:api_stub_body) do
    {
      content: [ {
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
      } ]
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

    it "sends you to a plan that's ready but not yet confirmed instead of replacing it" do
      plan = create(:meal_plan, user: user, status: "ready")
      get new_meal_plan_path
      expect(response).to redirect_to(meal_plan_path(plan))
    end

    it "shows the form when this week's plan failed" do
      create(:meal_plan, user: user, status: "failed")
      get new_meal_plan_path
      expect(response).to have_http_status(:ok)
    end

    it "brings back the last message on Try again" do
      perform_enqueued_jobs { post meal_plans_path, params: { message: "Tacos on Tuesday please" } }
      MealPlan.last.update!(status: "failed")

      get new_meal_plan_path(retry: 1)
      expect(response.body).to include("Tacos on Tuesday please")
    end
  end

  describe "POST /meal_plans" do
    it "creates a MealPlan and redirects to preview" do
      expect {
        perform_enqueued_jobs { post meal_plans_path, params: { message: "Keep it simple this week." } }
      }.to change(MealPlan, :count).by(1)

      expect(response).to redirect_to(meal_plan_path(MealPlan.last))
      expect(MealPlan.last.ai_response).to be_present
    end

    it "destroys an existing unconfirmed plan for the same week before creating" do
      existing = create(:meal_plan, user: user)
      expect {
        perform_enqueued_jobs { post meal_plans_path, params: { message: "Keep it simple." } }
      }.not_to change(MealPlan, :count)

      expect { existing.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect(MealPlan.last.ai_response).to be_present
    end

    it "requires a message" do
      expect {
        post meal_plans_path, params: { message: "  " }
      }.not_to change(MealPlan, :count)
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Tell me a little about your week")
    end

    it "rejects photos over 3.75 MB with a plain message and keeps the existing plan" do
      existing = create(:meal_plan, user: user, status: "failed")
      big = Tempfile.new([ "pantry", ".jpg" ])
      big.binmode
      big.write("0" * (MealPlan::MAX_IMAGE_BYTES + 1))
      big.rewind

      expect {
        post meal_plans_path, params: {
          message: "Use what's in the freezer",
          pantry_images: [ Rack::Test::UploadedFile.new(big.path, "image/jpeg", original_filename: "freezer.jpg") ]
        }
      }.not_to change(MealPlan, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("freezer.jpg is too large")
      expect(existing.reload).to be_persisted
    ensure
      big&.close!
    end

    it "doesn't replace a plan that's already confirmed for this week" do
      confirmed = create(:meal_plan, :confirmed, user: user)
      expect {
        post meal_plans_path, params: { message: "Something new" }
      }.not_to change(MealPlan, :count)
      expect(response).to redirect_to(meal_plan_path(confirmed))
    end

    it "budgets with the current household's Groceries envelope only" do
      other_groceries = create(:envelope, name: "Groceries")
      create(:envelope_budget, envelope: other_groceries, amount: 999)

      groceries = create(:envelope, account: user.account, name: "Groceries")
      create(:envelope_budget, envelope: groceries, amount: 300)
      create(:expense, envelope: groceries, user: user, amount: 50)

      expect {
        post meal_plans_path, params: { message: "Keep it cheap" }
      }.to have_enqueued_job(MealPlannerJob).with(anything, "Keep it cheap", 250)
    end
  end

  describe "DELETE /meal_plans/:id (Start over)" do
    it "deletes the unconfirmed plan and returns to the form with the last message" do
      plan = create(:meal_plan, user: user, status: "ready")
      delete meal_plan_path(plan)
      expect(response).to redirect_to(new_meal_plan_path(retry: 1))
      expect(MealPlan.exists?(plan.id)).to be false
    end

    it "can't delete another household's plan" do
      other_plan = create(:meal_plan)
      delete meal_plan_path(other_plan)
      expect(MealPlan.exists?(other_plan.id)).to be true
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

      it "shows an empty state when there are no shopping items" do
        get meal_plan_path(plan)
        expect(response.body).to include("Your shopping list is empty.")
      end

      it "shows only the current household's grocery money" do
        other_groceries = create(:envelope, name: "Groceries")
        create(:envelope_budget, envelope: other_groceries, amount: 999)
        groceries = create(:envelope, account: user.account, name: "Groceries")
        create(:envelope_budget, envelope: groceries, amount: 300)
        create(:expense, envelope: groceries, user: user, amount: 50)
        create(:shopping_item, meal_plan: plan)

        get meal_plan_path(plan)
        expect(response.body).to include("$250.00 left for groceries")
        expect(response.body).not_to include("$999")
      end
    end

    context "confirmed plan from a past week" do
      let(:plan) { create(:meal_plan, :confirmed, :prior_week, user: user) }

      it "is titled by its week, not 'This week'" do
        get meal_plan_path(plan)
        expect(response.body).not_to include("This week")
        expect(response.body).to include("Week of #{plan.week_start.strftime("%B %-d")}")
      end
    end

    context "plan still generating" do
      it "asks for a confirm before Start over" do
        plan = create(:meal_plan, user: user, status: "processing")
        get meal_plan_path(plan)
        expect(response.body).to include("Planning your week")
        expect(response.body).to include("data-turbo-confirm")
        expect(response.body).not_to include("Got your photos")
      end

      it "says so when it's taking longer than usual" do
        plan = create(:meal_plan, user: user, status: "processing", created_at: 3.minutes.ago)
        get meal_plan_path(plan)
        expect(response.body).to include("This is taking longer than usual.")
      end
    end

    it "redirects for another household's plan" do
      other_plan = create(:meal_plan, ai_response: { "meals" => [], "shopping_items" => [] })
      get meal_plan_path(other_plan)
      expect(response).to redirect_to(new_meal_plan_path)
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

    it "shows a plain message when a meal is missing" do
      patch confirm_meal_plan_path(plan), params: {
        meals: { "0" => { day_of_week: 0, dinner: "", lunch: "Leftovers" } }
      }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("every day has a dinner and a lunch")
      expect(response.body).not_to include("Validation failed")
      expect(plan.reload.confirmed?).to be false
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
