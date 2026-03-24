class PushSubscriptionsController < ApplicationController
  def create
    sub = params.require(:subscription)
    current_user.push_subscriptions.create!(
      endpoint: sub[:endpoint],
      auth:     sub.dig(:keys, :auth),
      p256dh:   sub.dig(:keys, :p256dh)
    )
    head :created
  rescue ActiveRecord::RecordInvalid
    head :unprocessable_content
  end

  def destroy
    subscription = current_user.push_subscriptions.find(params[:id])
    subscription.destroy
    head :no_content
  end
end
