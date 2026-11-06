class NavComponent < ApplicationComponent
  def initialize(current_user:, current_path:)
    @current_user = current_user
    @current_path = current_path
  end

  def owner?
    @current_user&.owner?
  end

  # Budget owns "/" and "/dashboard…" plus category pages; other tabs match by prefix.
  def active?(path)
    if path == root_path
      @current_path == "/" || @current_path.start_with?("/dashboard", "/envelopes", "/envelope_budgets")
    else
      @current_path.start_with?(path)
    end
  end

  def link_options(path)
    active = active?(path)
    { class: ui.nav_item(active: active), aria: { current: (active ? "page" : nil) } }
  end
end
