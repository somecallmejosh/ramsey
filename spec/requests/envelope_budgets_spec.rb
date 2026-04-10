require "rails_helper"

RSpec.describe "EnvelopeBudgets", type: :request do
  let(:account)  { create(:account) }
  let(:owner)    { create(:user, :owner, account: account) }
  let(:member)   { create(:user, account: account) }
  let(:envelope) { create(:envelope, account: account) }

  describe "PATCH /envelope_budgets/:id" do
    context "prior month budget, owner" do
      let(:budget) { create(:envelope_budget, :prior_month, envelope: envelope, amount: 500) }

      before { sign_in(owner) }

      it "does not update the amount (model-level guard)" do
        patch envelope_budget_path(budget), params: { envelope_budget: { amount: 999 } }
        expect(budget.reload.amount).to eq(500)
      end

      it "renders edit with unprocessable_entity status" do
        patch envelope_budget_path(budget), params: { envelope_budget: { amount: 999 } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "current month budget, owner" do
      let(:budget) { create(:envelope_budget, envelope: envelope, amount: 500) }

      before { sign_in(owner) }

      it "updates the amount and redirects to settings" do
        patch envelope_budget_path(budget), params: { envelope_budget: { amount: 750 } }
        expect(budget.reload.amount).to eq(750)
        expect(response).to redirect_to(admin_settings_path)
      end
    end

    context "any request from a member" do
      let(:budget) { create(:envelope_budget, envelope: envelope, amount: 500) }

      before { sign_in(member) }

      it "redirects to root (owner required)" do
        patch envelope_budget_path(budget), params: { envelope_budget: { amount: 750 } }
        expect(response).to redirect_to(root_path)
        expect(budget.reload.amount).to eq(500)
      end
    end

    context "unauthenticated" do
      let(:budget) { create(:envelope_budget, envelope: envelope, amount: 500) }

      it "redirects to sign in" do
        patch envelope_budget_path(budget), params: { envelope_budget: { amount: 750 } }
        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
