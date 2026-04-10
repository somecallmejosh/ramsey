class ApplicationController < ActionController::Base
  include Authentication
  include AccountScoped
  stale_when_importmap_changes

  before_action :check_session_expiry, if: :authenticated?

  helper_method :current_user

  def current_user
    Current.session&.user
  end

  private

  def check_session_expiry
    if Current.session&.last_active_at&.before?(24.hours.ago)
      Current.session.destroy
      redirect_to new_session_path, alert: "Your session expired. Please sign in again."
    else
      Current.session&.touch(:last_active_at)
    end
  end

  def store_location
    session[:return_to] = request.fullpath if request.get? && !request.xhr?
  end

  def redirect_back_or(default)
    redirect_to(session.delete(:return_to) || default)
  end
end
