require "rails_helper"

RSpec.describe "Invitations", type: :request do
  let(:account) { create(:account) }
  let(:owner)   { create(:user, :owner, account: account) }

  before { sign_in(owner) }

  describe "GET /invitations" do
    it "shows an empty state and how long links last" do
      get invitations_path
      expect(response.body).to include("No pending invites")
      expect(response.body).to include("Links work for 7 days")
      expect(response.body).to include("We don't send an email")
    end

    it "lists pending invites with a copy button and a named revoke confirm" do
      invitation = create(:invitation, account: account, invited_by: owner, email: "pat@example.com")
      get invitations_path
      expect(response.body).to include(accept_invitation_url(token: invitation.token))
      expect(response.body).to include('data-controller="clipboard"')
      expect(response.body).to include("Revoke the invite for pat@example.com?")
    end
  end

  describe "POST /invitations" do
    it "creates an invite that expires in 7 days" do
      post invitations_path, params: { email: "" }
      expect(Invitation.last.expires_at).to be_within(1.minute).of(7.days.from_now)
    end
  end

  describe "DELETE /invitations/:id" do
    it "revokes the invite" do
      invitation = create(:invitation, account: account, invited_by: owner)
      expect { delete invitation_path(invitation) }.to change(Invitation, :count).by(-1)
    end
  end
end
