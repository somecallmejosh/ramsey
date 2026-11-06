class PushSubscriptionsController < ApplicationController
  # Idempotent: the browser re-sends its subscription on every visit so a
  # pruned or rotated one heals itself. One device signs in as someone else →
  # the subscription moves to them.
  def create
    sub = params.require(:subscription)
    subscription = PushSubscription.find_or_initialize_by(endpoint: sub[:endpoint])
    subscription.update!(
      user:   current_user,
      auth:   sub.dig(:keys, :auth),
      p256dh: sub.dig(:keys, :p256dh)
    )
    head :created
  rescue ActiveRecord::RecordInvalid, ActionController::ParameterMissing
    head :unprocessable_content
  end

  def destroy
    current_user.push_subscriptions.find(params[:id]).destroy
    head :no_content
  end
end
