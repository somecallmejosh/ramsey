# Lets any signed-in user opt in or out of household push notifications.
# The switch is per person, so it covers every device they've signed in on.
class NotificationPreferencesController < ApplicationController
  def update
    enabled = ActiveModel::Type::Boolean.new.cast(params[:notifications_enabled])
    current_user.update!(notifications_enabled: enabled)

    redirect_to admin_settings_path,
                notice: enabled ? "Notifications are on." : "Notifications are off. You won't get any household alerts."
  end
end
