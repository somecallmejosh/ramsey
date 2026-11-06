require "rails_helper"

RSpec.describe DebtCardComponent, type: :component do
  let(:owner)  { create(:user, :owner) }
  let(:member) { create(:user) }

  it "formats the APR without a doubled percent sign or trailing zeros" do
    debt = create(:debt, interest_rate: 22.99)
    html = render_inline(described_class.new(debt: debt, current_user: member)).to_html
    expect(html).to include("22.99% APR")
    expect(html).not_to include("%%")
  end

  it "labels the first snowball debt in plain words" do
    debt = create(:debt)
    html = render_inline(described_class.new(debt: debt, current_user: member, snowball_target: true)).to_html
    expect(html).to include("Paying off next")
    expect(html).not_to include("Target")
  end

  it "exposes progress as an accessible progressbar" do
    debt = create(:debt, original_balance: 1_000, current_balance: 750)
    result = render_inline(described_class.new(debt: debt, current_user: member))
    bar = result.css('[role="progressbar"]').first
    expect(bar["aria-valuenow"]).to eq("25.0")
    expect(bar["aria-valuemax"]).to eq("100")
  end

  it "shows Move up / Move down to owners only" do
    debt = create(:debt)
    owner_html = render_inline(described_class.new(debt: debt, current_user: owner, can_move_up: true, can_move_down: true)).to_html
    expect(owner_html).to include("Move up").and include("Move down")

    member_html = render_inline(described_class.new(debt: debt, current_user: member, can_move_up: true, can_move_down: true)).to_html
    expect(member_html).not_to include("Move up")
  end
end
