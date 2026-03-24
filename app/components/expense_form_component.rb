class ExpenseFormComponent < ApplicationComponent
  def initialize(expense:, envelope:)
    @expense  = expense
    @envelope = envelope
  end
end
