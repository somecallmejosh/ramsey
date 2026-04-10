require "rails_helper"

RSpec.describe "Envelopes", type: :request do
  let(:account)  { create(:account) }
  let(:owner)    { create(:user, :owner, account: account) }
  let(:member)   { create(:user, account: account) }
  let(:envelope) { create(:envelope, account: account) }

  describe "admin-only write actions" do
    context "as a member" do
      before { sign_in(member) }

      it "GET /envelopes/new redirects to root" do
        get new_envelope_path
        expect(response).to redirect_to(root_path)
      end

      it "POST /envelopes redirects to root" do
        post envelopes_path, params: { envelope: { name: "Test", active: true }, envelope_budget_amount: 100 }
        expect(response).to redirect_to(root_path)
      end

      it "GET /envelopes/:id/edit redirects to root" do
        get edit_envelope_path(envelope)
        expect(response).to redirect_to(root_path)
      end

      it "PATCH /envelopes/:id redirects to root" do
        patch envelope_path(envelope), params: { envelope: { name: "New Name" } }
        expect(response).to redirect_to(root_path)
      end
    end

    context "as an owner" do
      before { sign_in(owner) }

      it "GET /envelopes/new is accessible" do
        get new_envelope_path
        expect(response).to have_http_status(:ok)
      end

      it "GET /envelopes/:id/edit is accessible" do
        create(:envelope_budget, envelope: envelope, year: Date.current.year, month: Date.current.month)
        get edit_envelope_path(envelope)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "unauthenticated access" do
    it "redirects to login" do
      get new_envelope_path
      expect(response).to redirect_to(new_session_path)
    end
  end
end
