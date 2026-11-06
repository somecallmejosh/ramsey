require "rails_helper"

RSpec.describe "Passwords", type: :request do
  let(:user) { create(:user) }
  let(:token) { user.password_reset_token }

  describe "GET /passwords/new" do
    it "renders a labelled email field and a way back" do
      get new_password_path
      expect(response.body).to include('<label for="email_address"')
      expect(response.body).to include("Back to sign in")
      expect(response.body).not_to include("color:red")
    end
  end

  describe "POST /passwords" do
    it "emails a known user" do
      expect { post passwords_path, params: { email_address: user.email_address } }
        .to have_enqueued_mail(PasswordsMailer, :reset)
      expect(response).to redirect_to(new_session_path)
    end

    it "gives the same answer for an unknown email" do
      expect { post passwords_path, params: { email_address: "nobody@example.com" } }
        .not_to have_enqueued_mail(PasswordsMailer, :reset)
      expect(response).to redirect_to(new_session_path)
    end
  end

  describe "GET /passwords/:token/edit" do
    it "renders the form for a valid token" do
      get edit_password_path(token)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("At least 8 characters")
    end

    it "sends a bad token back to request a new link" do
      get edit_password_path("bogus")
      expect(response).to redirect_to(new_password_path)
    end
  end

  describe "PUT /passwords/:token" do
    it "changes the password and signs out other sessions" do
      user.sessions.create!
      put password_path(token), params: { password: "brand-new-pass", password_confirmation: "brand-new-pass" }
      expect(response).to redirect_to(new_session_path)
      expect(user.reload.authenticate("brand-new-pass")).to be_truthy
      expect(user.sessions).to be_empty
    end

    it "re-renders with the real error when confirmation doesn't match" do
      put password_path(token), params: { password: "brand-new-pass", password_confirmation: "different" }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Password confirmation doesn&#39;t match Password")
      expect(response.body).to include('id="password_confirmation_error"')
    end

    it "re-renders when the password is too short" do
      put password_path(token), params: { password: "short", password_confirmation: "short" }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Password is too short")
    end

    it "does not pretend to succeed with a blank password" do
      put password_path(token), params: { password: "", password_confirmation: "" }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Password can&#39;t be blank")
    end
  end
end
