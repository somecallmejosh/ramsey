class MealPlansController < ApplicationController
  # Kept in the cookie session for "Try again", so cap its size.
  MESSAGE_MEMORY_LIMIT = 1_000

  before_action :set_meal_plan, only: [ :show, :confirm, :reuse, :destroy ]

  # GET /meal_plans
  def index
    @meal_plans = current_account.meal_plans.confirmed.includes(:meals).order(week_start: :desc)
  end

  # GET /meal_plans/new
  def new
    this_week = Date.current.beginning_of_week(:sunday)

    # Send them back to a plan that's still generating or waiting for review,
    # rather than letting a new request silently replace it.
    plan = current_account.meal_plans.unconfirmed.find_by(week_start: this_week)
    if plan && (plan.pending? || plan.processing? || plan.ready?)
      redirect_to meal_plan_path(plan) and return
    end

    # "Try again" after a failure brings back what they typed.
    @message = session[:meal_plan_message] if params[:retry].present?
  end

  # POST /meal_plans
  def create
    week_start = Date.current.beginning_of_week(:sunday)
    @message   = params[:message].to_s.strip

    if (confirmed = current_account.meal_plans.confirmed.find_by(week_start: week_start))
      redirect_to meal_plan_path(confirmed), alert: "You already have a meal plan for this week." and return
    end

    if @message.blank?
      flash.now[:alert] = "Tell me a little about your week so I can plan around it."
      render :new, status: :unprocessable_content and return
    end

    @meal_plan = current_account.meal_plans.build(user: current_user, week_start: week_start)
    @meal_plan.pantry_images.attach(params[:pantry_images]) if params[:pantry_images].present?

    # Replace any unfinished plan for this week, but keep it if the new one is rejected.
    saved = MealPlan.transaction do
      current_account.meal_plans.unconfirmed.where(week_start: week_start).destroy_all
      @meal_plan.save || raise(ActiveRecord::Rollback)
    end

    unless saved
      flash.now[:alert] = @meal_plan.errors.full_messages.first
      render :new, status: :unprocessable_content and return
    end

    session[:meal_plan_message] = @message.first(MESSAGE_MEMORY_LIMIT)
    groceries_remaining = helpers.current_groceries_remaining
    MealPlannerJob.perform_later(@meal_plan.id, @message, groceries_remaining)

    redirect_to meal_plan_path(@meal_plan)
  end

  # GET /meal_plans/:id  — preview (unconfirmed) or confirmed view
  def show
  end

  # POST /meal_plans/:id/reuse
  def reuse
    this_week = Date.current.beginning_of_week(:sunday)

    if current_account.meal_plans.confirmed.exists?(week_start: this_week)
      redirect_to meal_plans_path, alert: "You already have a confirmed plan for this week." and return
    end

    current_account.meal_plans.unconfirmed.where(week_start: this_week).destroy_all

    new_plan = current_account.meal_plans.create!(user: current_user, week_start: this_week, status: "ready", confirmed_at: Time.current)

    @meal_plan.meals.each do |m|
      new_plan.meals.create!(m.slice(:day_of_week, :dinner, :lunch, :prep_note, :estimated_cost))
    end
    @meal_plan.shopping_items.each do |i|
      new_plan.shopping_items.create!(i.slice(:name, :quantity, :estimated_cost, :store))
    end

    redirect_to meal_plan_path(new_plan), notice: "Meal plan applied for this week!"
  end

  # DELETE /meal_plans/:id  — "Start over"
  def destroy
    @meal_plan.destroy
    redirect_to new_meal_plan_path(retry: (1 unless @meal_plan.confirmed?))
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
  rescue ActiveRecord::RecordInvalid
    flash.now[:alert] = "We couldn't save this plan. Make sure every day has a dinner and a lunch, then try again."
    render :show, status: :unprocessable_content
  end

  private

  def set_meal_plan
    @meal_plan = current_account.meal_plans.find_by(id: params[:id])
    redirect_to new_meal_plan_path unless @meal_plan
  end
end
