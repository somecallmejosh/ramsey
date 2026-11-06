require "rails_helper"

RSpec.describe "AccountPasswords", type: :request do
  let(:account) { create(:account) }
  let(:member)  { create(:user, account: account) }

  def change(current:, password: "newpassword1", confirmation: password)
    patch account_password_path, params: {
      current_password: current, password: password, password_confirmation: confirmation
    }
  end

  describe "GET /account/password/edit" do
    it "redirects to sign in when signed out" do
      get edit_account_password_path
      expect(response).to redirect_to(new_session_path)
    end

    it "is available to members, not just owners" do
      sign_in(member)
      get edit_account_password_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('<label for="current_password"')
      expect(response.body).to include("At least 8 characters")
    end

    it "is linked from Settings, which members can open" do
      sign_in(member)
      get root_path
      expect(response.body).to include(admin_settings_path)

      get admin_settings_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(edit_account_password_path)
    end
  end

  describe "PATCH /account/password" do
    before { sign_in(member) }

    it "changes the password and keeps this session signed in" do
      change(current: "password123")
      expect(response).to redirect_to(admin_settings_path)
      expect(flash[:notice]).to eq("Your password has been changed.")
      expect(member.reload.authenticate("newpassword1")).to be_truthy

      get edit_account_password_path
      expect(response).to have_http_status(:ok)
    end

    it "signs out the user's other sessions" do
      other = member.sessions.create!(user_agent: "other phone", ip_address: "1.2.3.4", last_active_at: Time.current)
      change(current: "password123")
      expect(Session.exists?(other.id)).to be(false)
      expect(member.sessions.count).to eq(1)
    end

    it "rejects a wrong current password" do
      change(current: "wrong-password")
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include('id="current_password_error"')
      expect(member.reload.authenticate("password123")).to be_truthy
    end

    it "rejects a blank new password" do
      change(current: "password123", password: "")
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include('id="password_error"')
      expect(member.reload.authenticate("password123")).to be_truthy
    end

    it "rejects a short new password" do
      change(current: "password123", password: "short")
      expect(response).to have_http_status(:unprocessable_entity)
      expect(member.reload.authenticate("password123")).to be_truthy
    end

    it "rejects a confirmation that doesn't match" do
      change(current: "password123", confirmation: "different1")
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include('id="password_confirmation_error"')
      expect(member.reload.authenticate("password123")).to be_truthy
    end
  end
end
