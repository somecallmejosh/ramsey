class MealPlansController < ApplicationController
  before_action :set_meal_plan, only: [ :show, :confirm ]

  # GET /meal_plans/new
  def new
    this_week = Date.current.beginning_of_week(:sunday)

    # Redirect to any in-progress or confirmed plan for this week
    if (plan = MealPlan.where(week_start: this_week).first)
      redirect_to meal_plan_path(plan) and return unless plan.failed?
    end
  end

  # POST /meal_plans
  def create
    week_start = Date.current.beginning_of_week(:sunday)

    # Destroy any existing unconfirmed plan for this week so the user can retry
    MealPlan.unconfirmed.where(week_start: week_start).destroy_all

    @meal_plan = MealPlan.new(user: current_user, week_start: week_start)

    if params[:pantry_images].present?
      @meal_plan.pantry_images.attach(params[:pantry_images])
    end

    unless @meal_plan.save
      flash.now[:alert] = @meal_plan.errors.full_messages.first
      render :new, status: :unprocessable_entity and return
    end

    groceries_remaining = helpers.current_groceries_remaining
    MealPlannerJob.perform_later(@meal_plan.id, params[:message].to_s.strip, groceries_remaining)

    redirect_to meal_plan_path(@meal_plan)
  end

  # GET /meal_plans/:id  — preview (unconfirmed) or confirmed view
  def show
  end

  # PATCH /meal_plans/:id/confirm
  def confirm
    if @meal_plan.confirmed?
      redirect_to meal_plan_path(@meal_plan), alert: "Already confirmed." and return
    end

    ai = @meal_plan.ai_response || {}

    # Form sends meals[0][...], meals[1][...] → params[:meals] is a hash keyed by "0","1",...
    # AI fallback is a plain Array. Normalise to Array in both cases.
    meals_data          = Array(params[:meals]&.values          || ai["meals"]          || [])
    shopping_items_data = Array(params[:shopping_items]&.values || ai["shopping_items"] || [])

    MealPlan.transaction do
      meals_data.each do |m|
        m = m.respond_to?(:with_indifferent_access) ? m.with_indifferent_access : m
        @meal_plan.meals.create!(
          day_of_week:    m[:day_of_week].to_i,
          dinner:         m[:dinner].to_s,
          lunch:          m[:lunch].to_s,
          prep_note:      m[:prep_note].presence,
          estimated_cost: m[:estimated_cost].to_f
        )
      end

      shopping_items_data.each do |i|
        i = i.respond_to?(:with_indifferent_access) ? i.with_indifferent_access : i
        @meal_plan.shopping_items.create!(
          name:           i[:name].to_s,
          quantity:       i[:quantity].to_s,
          estimated_cost: i[:estimated_cost]&.to_f,
          store:          i[:store].presence || "Aldi"
        )
      end

      @meal_plan.update!(confirmed_at: Time.current)
    end

    redirect_to meal_plan_path(@meal_plan), notice: "Meal plan confirmed!"
  rescue ActiveRecord::RecordInvalid => e
    flash.now[:alert] = e.message
    render :show, status: :unprocessable_entity
  end

  private

  def set_meal_plan
    @meal_plan = MealPlan.find(params[:id])
  end

end
