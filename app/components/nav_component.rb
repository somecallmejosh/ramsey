class NavComponent < ApplicationComponent
  def initialize(current_user:, current_path:)
    @current_user = current_user
    @current_path = current_path
  end

  def owner?
    @current_user&.owner?
  end

  def active?(path)
    @current_path.start_with?(path)
  end
end
