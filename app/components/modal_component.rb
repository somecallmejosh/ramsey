class ModalComponent < ApplicationComponent
  renders_one :body

  def initialize(title:, id:, open: false)
    @title = title
    @id    = id
    @open  = open
  end
end
