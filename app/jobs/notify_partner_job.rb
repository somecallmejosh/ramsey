class NotifyPartnerJob < ApplicationJob
  queue_as :default

  def perform(resource_type, resource_id)
    resource = resource_type.constantize.find_by(id: resource_id)
    return unless resource

    partner = User.where.not(id: resource.user_id).first
    return unless partner

    subscriptions = partner.push_subscriptions.to_a
    return if subscriptions.empty?

    payload = build_payload(resource)
    subscriptions.each { |sub| deliver(sub, payload) }
  end

  private

  def build_payload(resource)
    name = resource.user.email_address.split("@").first.capitalize
    body = case resource
    when Expense
      envelope    = resource.envelope
      year, month = resource.transacted_on.year, resource.transacted_on.month
      spent       = envelope.expenses.for_month(year, month).sum(:amount)
      budget      = EnvelopeBudget.find_by(envelope: envelope, year: year, month: month)
      remaining   = (budget&.amount || 0) - spent
      "#{name} logged #{currency(resource.amount)} to #{envelope.name}. #{currency(remaining)} remaining."
    when LunchLog
      "#{name} packed lunch today."
    end
    { title: "Ramsey", body: body, icon: "/icons/icon-192.png" }
  end

  def deliver(subscription, payload)
    WebPush.payload_send(
      message:    payload.to_json,
      endpoint:   subscription.endpoint,
      p256dh:     subscription.p256dh,
      auth:       subscription.auth,
      vapid: {
        subject:     Rails.application.credentials.dig(:push_notifications, :subject),
        public_key:  Rails.application.credentials.dig(:push_notifications, :vapid_public_key),
        private_key: Rails.application.credentials.dig(:push_notifications, :vapid_private_key)
      }
    )
  rescue WebPush::ExpiredSubscription, WebPush::InvalidSubscription
    subscription.destroy
  end

  def currency(amount)
    ActiveSupport::NumberHelper.number_to_currency(amount)
  end
end
