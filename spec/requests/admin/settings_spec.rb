require "rails_helper"

RSpec.describe "Admin::Settings", type: :request do
  let(:account) { create(:account) }
  let(:owner)   { create(:user, :owner, account: account) }
  let(:member)  { create(:user, account: account) }

  describe "GET /admin/settings" do
    it "shows a member only their own account section" do
      sign_in(member)
      get admin_settings_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Your account")
      expect(response.body).to include(edit_account_password_path)
      expect(response.body).not_to include("Monthly budgets")
      expect(response.body).not_to include("Invite someone")
      expect(response.body).not_to include("Delete household")
    end

    it "shows an owner their account and the household sections" do
      sign_in(owner)
      get admin_settings_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Your account")
      expect(response.body).to include("Monthly budgets")
      expect(response.body).to include("Invite someone")
      expect(response.body).to include("Delete household")
    end
  end

  describe "PATCH /admin/settings" do
    it "still turns members away from saving budgets" do
      sign_in(member)
      patch admin_settings_path, params: { budgets: {} }
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("Only the household owner can do that.")
    end
  end
end
