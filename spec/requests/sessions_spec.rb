require "rails_helper"

RSpec.describe "Sessions", type: :request do
  let(:user) { create(:user) }

  describe "GET /session/new" do
    it "renders the sign-in form with a password toggle and busy text" do
      get new_session_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('data-controller="password-visibility"')
      expect(response.body).to include("Signing in…")
      expect(response.body).not_to include("<br>")
    end
  end

  describe "POST /session" do
    it "signs in with the right credentials" do
      post session_path, params: { email_address: user.email_address, password: "password123" }
      expect(response).to redirect_to(root_url)
    end

    it "re-renders with one error and keeps the email" do
      post session_path, params: { email_address: user.email_address, password: "wrong-password" }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body.scan("That email and password don&#39;t match").size).to eq(1)
      expect(response.body).to include(%(value="#{user.email_address}"))
    end
  end

  describe "password reset confirmation" do
    it "shows a lasting check-your-inbox message after requesting a reset" do
      post passwords_path, params: { email_address: user.email_address }
      follow_redirect!
      expect(response.body).to include("we've sent a reset link. Check your inbox.")
    end
  end
end
