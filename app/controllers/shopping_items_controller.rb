class ShoppingItemsController < ApplicationController
  before_action :set_shopping_item

  def update
    @shopping_item.update!(checked: params[:shopping_item][:checked])
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to meal_plan_path(@shopping_item.meal_plan) }
    end
  end

  private

  def set_shopping_item
    @shopping_item = ShoppingItem.find(params[:id])
  end
end
