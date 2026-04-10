module RequireOwner
  extend ActiveSupport::Concern

  # Do NOT add `before_action :require_owner_role` in an `included do` block.
  # That would apply it to all actions automatically on include, requiring
  # skip_before_action everywhere else. Instead, call it explicitly with `only:`
  # in each controller — authorization is opt-in and visible at declaration.

  private

  def require_owner_role
    redirect_to root_path, alert: "Not authorized." unless current_user.owner?
  end
end
