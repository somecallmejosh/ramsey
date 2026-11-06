# Short confirmation shown at the bottom of the screen after an action.
# Pass undo_path to offer a one-tap reversal (sent as DELETE by default;
# use undo_method: :post and undo_params to undo a delete).
class ToastComponent < ApplicationComponent
  def initialize(message:, detail: nil, undo_path: nil, undo_method: :delete, undo_params: {}, tone: :success)
    @message     = message
    @detail      = detail
    @undo_path   = undo_path
    @undo_method = undo_method
    @undo_params = undo_params
    @tone        = tone
  end

  def timeout
    @undo_path ? 10_000 : 4_000
  end

  def icon_name
    @tone == :success ? "check-circle" : "info"
  end
end
