require "rails_helper"

RSpec.describe "Admin::Debts", type: :request do
  let(:account)  { create(:account) }
  let(:owner)    { create(:user, :owner, account: account) }
  let(:member)   { create(:user, account: account) }

  describe "GET /admin/debts/new" do
    context "member" do
      before { sign_in(member) }

      it "redirects to root" do
        get new_admin_debt_path
        expect(response).to redirect_to(root_path)
      end
    end

    context "owner" do
      before { sign_in(owner) }

      it "returns 200" do
        get new_admin_debt_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "POST /admin/debts" do
    context "owner" do
      before { sign_in(owner) }

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

    context "member" do
      before { sign_in(member) }

      it "redirects to root" do
        post admin_debts_path, params: {
          debt: { name: "Test Loan", debt_type: "personal_loan" }
        }
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "GET /admin/debts/:id/edit" do
    let(:debt) { create(:debt, account: account) }

    context "owner" do
      before { sign_in(owner) }

      it "returns 200" do
        get edit_admin_debt_path(debt)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "PATCH /admin/debts/:id" do
    let(:debt) { create(:debt, account: account, name: "Old Name") }

    context "owner" do
      before { sign_in(owner) }

      it "updates the debt" do
        patch admin_debt_path(debt), params: {
          debt: { name: "New Name" }
        }
        expect(response).to redirect_to(debts_path)
        expect(debt.reload.name).to eq("New Name")
      end
    end
  end

  describe "PATCH /admin/debts/:id (balance to zero)" do
    let(:debt) { create(:debt, account: account) }

    before { sign_in(owner) }

    it "marks the debt paid off" do
      patch admin_debt_path(debt), params: { debt: { current_balance: "0" } }
      expect(debt.reload.paid_off_at).to eq(Date.current)
    end

    it "ignores a submitted position" do
      expect {
        patch admin_debt_path(debt), params: { debt: { position: "99" } }
      }.not_to change { debt.reload.position }
    end

    it "re-renders with inline errors" do
      patch admin_debt_path(debt), params: { debt: { name: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include('id="debt_name_error"')
    end
  end

  describe "PATCH /admin/debts/:id/move" do
    let!(:first)  { create(:debt, account: account, position: 1) }
    let!(:second) { create(:debt, account: account, position: 2) }

    context "owner" do
      before { sign_in(owner) }

      it "moves the debt up" do
        patch move_admin_debt_path(second, direction: "up")
        expect(response).to redirect_to(debts_path)
        expect(account.debts.ordered.to_a).to eq([ second, first ])
      end
    end

    context "member" do
      before { sign_in(member) }

      it "is not allowed" do
        patch move_admin_debt_path(second, direction: "up")
        expect(response).to redirect_to(root_path)
        expect(account.debts.ordered.to_a).to eq([ first, second ])
      end
    end
  end
end
