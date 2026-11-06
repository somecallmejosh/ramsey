require "rails_helper"

RSpec.describe "ShoppingItems", type: :request do
  let(:user)       { create(:user) }
  let(:plan)       { create(:meal_plan, :confirmed, user: user) }
  let(:other_plan) { create(:meal_plan, :confirmed) }
  let(:turbo)      { { "Accept" => "text/vnd.turbo-stream.html" } }

  before { sign_in(user) }

  describe "POST /shopping_items" do
    it "adds an item to your own plan" do
      expect {
        post shopping_items_path, params: { shopping_item: { meal_plan_id: plan.id, name: "Milk" } }, headers: turbo
      }.to change { plan.shopping_items.count }.by(1)
    end

    it "returns 404 for another household's plan" do
      expect {
        post shopping_items_path, params: { shopping_item: { meal_plan_id: other_plan.id, name: "Milk" } }
      }.not_to change(ShoppingItem, :count)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /shopping_items/:id" do
    it "checks off your own item" do
      item = create(:shopping_item, meal_plan: plan)
      patch shopping_item_path(item), params: { shopping_item: { checked: "1" } }, headers: turbo
      expect(item.reload.checked).to be true
      expect(response.body).to include(%(id="shopping_item_#{item.id}"))
    end

    it "returns 404 for another household's item" do
      item = create(:shopping_item, meal_plan: other_plan)
      patch shopping_item_path(item), params: { shopping_item: { checked: "1" } }
      expect(response).to have_http_status(:not_found)
      expect(item.reload.checked).to be false
    end
  end

  describe "DELETE /shopping_items/:id" do
    it "removes the item and offers Undo" do
      item = create(:shopping_item, meal_plan: plan, name: "Eggs")
      delete shopping_item_path(item), headers: turbo
      expect(ShoppingItem.exists?(item.id)).to be false
      expect(response.body).to include("Removed Eggs")
      expect(response.body).to include("Undo")
      expect(response.body).to include(%(action="/shopping_items/restore"))
      expect(response.body).to include(%(name="name" value="Eggs"))
    end

    it "shows the empty state once the last item is gone" do
      item = create(:shopping_item, meal_plan: plan)
      delete shopping_item_path(item), headers: turbo
      expect(response.body).to include("Your shopping list is empty.")
    end

    it "returns 404 for another household's item and leaves it alone" do
      item = create(:shopping_item, meal_plan: other_plan)
      delete shopping_item_path(item)
      expect(response).to have_http_status(:not_found)
      expect(ShoppingItem.exists?(item.id)).to be true
    end
  end

  describe "POST /shopping_items/restore (Undo)" do
    it "puts the removed item back" do
      expect {
        post restore_shopping_items_path,
             params: { meal_plan_id: plan.id, name: "Eggs", quantity: "1 dozen", store: "Costco", estimated_cost: "3.5" },
             headers: turbo
      }.to change { plan.shopping_items.count }.by(1)

      item = plan.shopping_items.last
      expect(item.slice(:name, :quantity, :store)).to eq("name" => "Eggs", "quantity" => "1 dozen", "store" => "Costco")
      expect(item.estimated_cost).to eq(3.5)
      expect(response.body).to include("Eggs")
    end

    it "returns 404 for another household's plan" do
      expect {
        post restore_shopping_items_path, params: { meal_plan_id: other_plan.id, name: "Eggs" }
      }.not_to change(ShoppingItem, :count)
      expect(response).to have_http_status(:not_found)
    end
  end
end
