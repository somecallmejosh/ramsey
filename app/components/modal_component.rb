class ModalComponent < ApplicationComponent
  renders_one :body

  def initialize(title:, id:)
    @title = title
    @id    = id
  end
end
