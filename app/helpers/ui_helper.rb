module UiHelper
  def ui
    @ui ||= UiPresenter.new
  end
end
