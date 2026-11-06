# Sends a web push to everyone in the household about something one member
# did. Expenses: see ExpenseNotification for who hears what.
class NotifyAccountMembersJob < ApplicationJob
  queue_as :default

  RESOURCES = { "Expense" => "Expense", "LunchLog" => "LunchLog" }.freeze
  ICON  = "/web-app-manifest-192x192.png".freeze
  BADGE = "/notification-badge.png".freeze

  def perform(resource_type, resource_id)
    return unless vapid_configured?

    resource = RESOURCES.fetch(resource_type).constantize.find_by(id: resource_id)
    return unless resource

    actor  = resource.user
    others = actor.account.users.where.not(id: actor.id)

    case resource
    when Expense
      notification = ExpenseNotification.new(resource)
      notify(others, notification.for_household)
      notify([ actor ], notification.for_logger)
    when LunchLog
      notify(others, title: "Lunch packed", body: "#{actor.display_name} packed lunch today.", url: "/lunch_logs")
    end
  end

  private

  def notify(users, payload)
    return unless payload

    message = payload.merge(icon: ICON, badge: BADGE).to_json
    PushSubscription.joins(:user)
      .where(user: users, users: { notifications_enabled: true })
      .find_each { |sub| deliver(sub, message) }
  end

  # One bad subscription must not stop the others, and must not raise: a retry
  # would re-send to everyone who already got it.
  def deliver(subscription, message)
    WebPush.payload_send(
      message:  message,
      endpoint: subscription.endpoint,
      p256dh:   subscription.p256dh,
      auth:     subscription.auth,
      vapid:    vapid
    )
  rescue WebPush::ExpiredSubscription, WebPush::InvalidSubscription
    subscription.destroy
  rescue WebPush::Error, Net::OpenTimeout, Net::ReadTimeout, SocketError => e
    Rails.logger.warn("[push] #{e.class} for subscription #{subscription.id}: #{e.message}")
  end

  def vapid
    creds = Rails.application.credentials.push_notifications || {}
    { subject: creds[:subject], public_key: creds[:vapid_public_key], private_key: creds[:vapid_private_key] }
  end

  def vapid_configured?
    return true if vapid.values.all?(&:present?)

    Rails.logger.warn("[push] VAPID credentials missing; skipping notifications")
    false
  end
end
