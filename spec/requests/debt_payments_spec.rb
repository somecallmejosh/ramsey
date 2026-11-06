require "rails_helper"

RSpec.describe "DebtPayments", type: :request do
  let(:account)  { create(:account) }
  let(:owner)    { create(:user, :owner, account: account) }
  let(:member)   { create(:user, account: account) }
  let(:debt)     { create(:debt, account: account, original_balance: 10_000, current_balance: 10_000) }

  describe "POST /debts/:debt_id/debt_payments" do
    context "member" do
      before { sign_in(member) }

      it "creates a payment and updates debt balance" do
        post debt_debt_payments_path(debt), params: {
          debt_payment: { amount: "500", balance_after: "9500", paid_on: Date.current.to_s }
        }
        expect(response).to redirect_to(debt_path(debt))
        expect(debt.reload.current_balance).to eq(9_500)
      end

      it "re-renders form with inline errors and keeps entered values" do
        post debt_debt_payments_path(debt), params: {
          debt_payment: { amount: "-1", balance_after: "9500", paid_on: Date.current.to_s }
        }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include('id="debt_payment_amount_error"')
        expect(response.body).to include('aria-invalid="true"')
        expect(response.body).to include('value="9500')
      end
    end

    context "unauthenticated" do
      it "redirects to sign in" do
        post debt_debt_payments_path(debt), params: {
          debt_payment: { amount: "500", balance_after: "9500", paid_on: Date.current.to_s }
        }
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "DELETE /debts/:debt_id/debt_payments/:id" do
    let!(:payment) { create(:debt_payment, debt: debt, user: member) }

    context "member" do
      before { sign_in(member) }

      it "redirects with a plain explanation" do
        delete debt_debt_payment_path(debt, payment)
        expect(response).to redirect_to(debt_path(debt))
        expect(flash[:alert]).to eq("Only the household owner can remove payments.")
        expect(payment.reload).to be_persisted
      end
    end

    context "owner" do
      before { sign_in(owner) }

      it "deletes the payment and restores the balance" do
        expect(debt.reload.current_balance).to eq(9_500)
        delete debt_debt_payment_path(debt, payment)
        expect { payment.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect(debt.reload.current_balance).to eq(10_000)
        expect(flash[:notice]).to eq("Removed the $500.00 payment. Balance is now $10,000.00.")
      end
    end
  end
end
