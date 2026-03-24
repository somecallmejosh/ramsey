require "rails_helper"

RSpec.describe ModalComponent, type: :component do
  it "renders with correct ARIA attributes" do
    result = render_inline(ModalComponent.new(title: "Log Expense", id: "expense-modal"))
    html   = result.to_html
    expect(html).to include('role="dialog"')
    expect(html).to include('aria-modal="true"')
    expect(html).to include('aria-labelledby="expense-modal-title"')
  end

  it "renders the title" do
    result = render_inline(ModalComponent.new(title: "Log Expense", id: "expense-modal"))
    expect(result.text).to include("Log Expense")
  end

  it "renders hidden by default" do
    result = render_inline(ModalComponent.new(title: "Test", id: "test-modal"))
    expect(result.to_html).to include("hidden")
  end

  it "has a close button with aria-label" do
    result = render_inline(ModalComponent.new(title: "Test", id: "test-modal"))
    expect(result.to_html).to include('aria-label="Close dialog"')
  end
end
