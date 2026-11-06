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

  describe "GET /debts empty and paid-off states" do
    it "tells members to ask the owner when there are no debts" do
      debt.destroy!
      sign_in(member)
      get debts_path
      expect(response.body).to include("Ask the household owner to add your debts.")
    end

    it "congratulates when every debt is paid off" do
      debt.update!(current_balance: 0)
      sign_in(member)
      get debts_path
      expect(response.body).to include("debt-free")
    end
  end

  describe "GET /debts/:id payment list" do
    before do
      debt.update!(current_balance: 1_221.51)
      create(:debt_payment, debt: debt, user: owner, amount: 95, balance_after: 1_126.51,
                            paid_on: Date.new(2026, 10, 3))
      sign_in(owner)
    end

    it "names the payment and the restored balance in the remove confirmation" do
      get debt_path(debt)
      expect(response.body).to include("Remove the $95.00 payment from Oct 3? The balance goes back to $1,221.51.")
      expect(response.body).to include('aria-label="Remove the $95.00 payment from Oct 3"')
      expect(response.body).to include(owner.display_name)
      expect(response.body).to include("Balance after")
    end
  end
end
