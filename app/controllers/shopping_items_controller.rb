class ShoppingItemsController < ApplicationController
  before_action :set_shopping_item, only: [ :update, :destroy ]

  def create
    @meal_plan = MealPlan.find(params[:shopping_item][:meal_plan_id])
    @shopping_item = @meal_plan.shopping_items.build(shopping_item_params)
    @shopping_item.save
    respond_to do |format|
      format.turbo_stream
      format.html do
        if @shopping_item.persisted?
          redirect_to meal_plan_path(@meal_plan)
        else
          redirect_to meal_plan_path(@meal_plan), alert: @shopping_item.errors.full_messages.to_sentence
        end
      end
    end
  end

  def update
    @shopping_item.update!(checked: params[:shopping_item][:checked])
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to meal_plan_path(@shopping_item.meal_plan) }
    end
  end

  def destroy
    @meal_plan = @shopping_item.meal_plan
    @shopping_item.destroy!
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to meal_plan_path(@meal_plan) }
    end
  end

  private

  def set_shopping_item
    @shopping_item = ShoppingItem.find(params[:id])
  end

  def shopping_item_params
    params.require(:shopping_item).permit(:name, :quantity, :store, :estimated_cost)
  end
end
