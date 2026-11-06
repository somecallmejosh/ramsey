require "rails_helper"

RSpec.describe ToastComponent, type: :component do
  it "renders the message and an Undo button that deletes" do
    result = render_inline(described_class.new(message: "Saved $5.00 to Gas", undo_path: "/envelopes/1/expenses/2"))
    expect(result.text).to include("Saved $5.00 to Gas")
    form = result.at_css("form[action='/envelopes/1/expenses/2']")
    expect(form.at_css("input[name='_method']")["value"]).to eq("delete")
    expect(form.text).to include("Undo")
  end

  it "stays up longer when it offers Undo" do
    with_undo    = render_inline(described_class.new(message: "x", undo_path: "/x"))
    without_undo = render_inline(described_class.new(message: "x"))
    expect(with_undo.at_css("[data-flash-timeout-value]")["data-flash-timeout-value"].to_i)
      .to be > without_undo.at_css("[data-flash-timeout-value]")["data-flash-timeout-value"].to_i
    expect(without_undo.at_css("button[aria-label='Dismiss']")).to be_present
  end
end
