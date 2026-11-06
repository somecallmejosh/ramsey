require "rails_helper"

RSpec.describe "InvitationAcceptances", type: :request do
  let(:invitation) { create(:invitation) }
  let(:params) do
    { email_address: "joiner@example.com", password: "longenough", password_confirmation: "longenough" }
  end

  describe "GET /join/:token" do
    it "renders the join form" do
      get accept_invitation_path(token: invitation.token)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Join #{invitation.account.name}")
    end

    it "explains an expired link instead of redirecting" do
      invitation.update!(expires_at: 1.minute.ago)
      get accept_invitation_path(token: invitation.token)
      expect(response).to have_http_status(:gone)
      expect(response.body).to include("Ask the person who invited you to send a new one.")
    end

    it "explains a used link" do
      invitation.update!(accepted_at: 1.day.ago)
      get accept_invitation_path(token: invitation.token)
      expect(response).to have_http_status(:gone)
    end

    it "explains an unknown token" do
      get accept_invitation_path(token: "nope")
      expect(response).to have_http_status(:gone)
    end
  end

  describe "POST /join/:token" do
    it "creates a member and marks the invite accepted" do
      expect { post accept_invitation_path(token: invitation.token), params: params }
        .to change(invitation.account.users, :count).by(1)
      expect(invitation.reload).to be_accepted
      expect(response).to redirect_to(root_path)
    end

    it "shows field errors inline and keeps the email" do
      post accept_invitation_path(token: invitation.token),
           params: params.merge(password: "short", password_confirmation: "short")
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Password is too short")
      expect(response.body).to include('id="password_error"')
      expect(response.body).to include('value="joiner@example.com"')
      expect(invitation.reload).not_to be_accepted
    end
  end
end
