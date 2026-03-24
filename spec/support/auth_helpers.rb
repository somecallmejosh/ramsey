module AuthHelpers
  # For request specs: sign in via rack-test POST
  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: "password123" }
  end
end

RSpec.configure do |config|
  config.include AuthHelpers, type: :request
end
