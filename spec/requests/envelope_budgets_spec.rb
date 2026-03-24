require "rails_helper"

RSpec.describe "EnvelopeBudgets", type: :request do
  let(:admin)    { create(:user, :admin) }
  let(:standard) { create(:user) }
  let(:envelope) { create(:envelope) }

  describe "PATCH /envelope_budgets/:id" do
    context "prior month budget, admin user" do
      let(:budget) { create(:envelope_budget, :prior_month, envelope: envelope, amount: 500) }

      before { sign_in(admin) }

      it "does not update the amount (model-level guard)" do
        patch envelope_budget_path(budget), params: { envelope_budget: { amount: 999 } }
        expect(budget.reload.amount).to eq(500)
      end

      it "renders edit with unprocessable_entity status" do
        patch envelope_budget_path(budget), params: { envelope_budget: { amount: 999 } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "current month budget, admin user" do
      let(:budget) { create(:envelope_budget, envelope: envelope, amount: 500) }

      before { sign_in(admin) }

      it "updates the amount and redirects to settings" do
        patch envelope_budget_path(budget), params: { envelope_budget: { amount: 750 } }
        expect(budget.reload.amount).to eq(750)
        expect(response).to redirect_to(admin_settings_path)
      end
    end

    context "any request from a standard user" do
      let(:budget) { create(:envelope_budget, envelope: envelope, amount: 500) }

      before { sign_in(standard) }

      it "redirects to root (admin required)" do
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
