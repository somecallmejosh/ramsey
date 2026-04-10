require "rails_helper"

RSpec.describe NavComponent, type: :component do
  let(:owner)  { create(:user, :owner) }
  let(:member) { create(:user) }

  it "renders Budget nav item" do
    result = render_inline(NavComponent.new(current_user: member, current_path: "/"))
    expect(result.text).to include("Budget")
  end

  it "renders Meals nav item" do
    result = render_inline(NavComponent.new(current_user: member, current_path: "/"))
    expect(result.text).to include("Meals")
  end

  it "renders Lunch nav item" do
    result = render_inline(NavComponent.new(current_user: member, current_path: "/"))
    expect(result.text).to include("Lunch")
  end

  it "renders Debts nav item" do
    result = render_inline(NavComponent.new(current_user: member, current_path: "/"))
    expect(result.text).to include("Debts")
  end
end
