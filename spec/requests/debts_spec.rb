require "rails_helper"

RSpec.describe "Debts", type: :request do
  let(:account)  { create(:account) }
  let(:owner)    { create(:user, :owner, account: account) }
  let(:member)   { create(:user, account: account) }
  let!(:debt)    { create(:debt, account: account) }

  describe "GET /debts" do
    context "authenticated user" do
      before { sign_in(member) }

      it "returns 200" do
        get debts_path
        expect(response).to have_http_status(:ok)
      end
    end

    context "unauthenticated" do
      it "redirects to sign in" do
        get debts_path
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /debts/:id" do
    context "authenticated user" do
      before { sign_in(member) }

      it "returns 200" do
        get debt_path(debt)
        expect(response).to have_http_status(:ok)
      end
    end

    context "unauthenticated" do
      it "redirects to sign in" do
        get debt_path(debt)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
