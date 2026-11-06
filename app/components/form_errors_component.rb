# Error summary shown at the top of a form after a failed save.
# Pass the record (uses errors.full_messages) or a list of messages.
# Pair with ui.input(:error) and ui.field_error on the fields themselves.
class FormErrorsComponent < ApplicationComponent
  def initialize(record: nil, messages: nil)
    @messages = Array(messages.presence || record&.errors&.full_messages).compact_blank
  end

  def render?
    @messages.any?
  end
end
