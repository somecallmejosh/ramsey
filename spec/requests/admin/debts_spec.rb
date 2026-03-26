require "rails_helper"

RSpec.describe "Admin::Debts", type: :request do
  let(:admin)    { create(:user, :admin) }
  let(:standard) { create(:user) }

  describe "GET /admin/debts/new" do
    context "standard user" do
      before { sign_in(standard) }

      it "redirects to root" do
        get new_admin_debt_path
        expect(response).to redirect_to(root_path)
      end
    end

    context "admin user" do
      before { sign_in(admin) }

      it "returns 200" do
        get new_admin_debt_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "POST /admin/debts" do
    context "admin user" do
      before { sign_in(admin) }

      it "creates a debt and redirects to debts path" do
        post admin_debts_path, params: {
          debt: {
            name: "Test Loan", debt_type: "personal_loan",
            original_balance: "5000", current_balance: "5000",
            minimum_payment: "150", interest_rate: "10.0"
          }
        }
        expect(response).to redirect_to(debts_path)
        expect(Debt.find_by(name: "Test Loan")).to be_present
      end
    end

    context "standard user" do
      before { sign_in(standard) }

      it "redirects to root" do
        post admin_debts_path, params: {
          debt: { name: "Test Loan", debt_type: "personal_loan" }
        }
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "GET /admin/debts/:id/edit" do
    let(:debt) { create(:debt) }

    context "admin user" do
      before { sign_in(admin) }

      it "returns 200" do
        get edit_admin_debt_path(debt)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "PATCH /admin/debts/:id" do
    let(:debt) { create(:debt, name: "Old Name") }

    context "admin user" do
      before { sign_in(admin) }

      it "updates the debt" do
        patch admin_debt_path(debt), params: {
          debt: { name: "New Name" }
        }
        expect(response).to redirect_to(debts_path)
        expect(debt.reload.name).to eq("New Name")
      end
    end
  end
end
