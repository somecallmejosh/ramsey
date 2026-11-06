require "rails_helper"

RSpec.describe "Registrations", type: :request do
  let(:valid_params) do
    { account_name: "Smith Household", email_address: "new@example.com",
      password: "longenough", password_confirmation: "longenough" }
  end

  describe "GET /registration/new" do
    it "shows the password hint" do
      get new_registration_path
      expect(response.body).to include("At least 8 characters")
      expect(response.body).to include("Creating account…")
    end
  end

  describe "POST /registration" do
    it "creates an account and owner, then signs in" do
      expect { post registration_path, params: valid_params }
        .to change(Account, :count).by(1).and change(User, :count).by(1)
      expect(User.last).to be_owner
      expect(response).to redirect_to(root_path)
    end

    it "shows every problem inline at once and keeps what was typed" do
      expect {
        post registration_path, params: valid_params.merge(account_name: "", password: "short", password_confirmation: "nope")
      }.not_to change(Account, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      body = response.body
      expect(body).to include("Household name can&#39;t be blank")
      expect(body).to include("Password is too short")
      expect(body).to include('id="account_name_error"')
      expect(body).to include('id="password_error"')
      expect(body).to include('aria-invalid="true"')
      expect(body).to include('value="new@example.com"')
    end

    it "reports a taken email without creating an orphan account" do
      create(:user, email_address: "new@example.com")
      expect { post registration_path, params: valid_params }.not_to change(Account, :count)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Email address has already been taken")
    end
  end
end
