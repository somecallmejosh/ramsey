require "rails_helper"

RSpec.describe NavComponent, type: :component do
  let(:admin)    { create(:user, :admin) }
  let(:standard) { create(:user) }

  it "renders Settings link for admin" do
    result = render_inline(NavComponent.new(current_user: admin, current_path: "/"))
    expect(result.text).to include("Settings")
  end

  it "does not render Settings link for standard user" do
    result = render_inline(NavComponent.new(current_user: standard, current_path: "/"))
    expect(result.text).not_to include("Settings")
  end

  it "renders Budget nav item" do
    result = render_inline(NavComponent.new(current_user: standard, current_path: "/"))
    expect(result.text).to include("Budget")
  end

  it "renders Sign out button" do
    result = render_inline(NavComponent.new(current_user: standard, current_path: "/"))
    expect(result.text).to include("Sign out")
  end
end
