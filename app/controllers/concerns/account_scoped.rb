module AccountScoped
  extend ActiveSupport::Concern

  included do
    helper_method :current_account
  end

  private

  def current_account
    current_user&.account
  end
end
