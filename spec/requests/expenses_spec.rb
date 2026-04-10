require "rails_helper"

RSpec.describe "Expenses", type: :request do
  let(:account)  { create(:account) }
  let(:owner)    { create(:user, :owner, account: account) }
  let(:member)   { create(:user, account: account) }
  let(:envelope) { create(:envelope, account: account) }

  describe "GET /envelopes/:envelope_id/expenses" do
    context "authenticated member" do
      before { sign_in(member) }

      it "returns 200 for current month" do
        get envelope_expenses_path(envelope)
        expect(response).to have_http_status(:ok)
      end

      it "returns 200 for a prior month" do
        get envelope_expenses_path(envelope, year: Date.current.last_month.year,
                                             month: Date.current.last_month.month)
        expect(response).to have_http_status(:ok)
      end
    end

    context "unauthenticated" do
      it "redirects to sign in" do
        get envelope_expenses_path(envelope)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "DELETE /envelopes/:envelope_id/expenses/:id" do
    context "prior month expense, member" do
      let(:expense) { create(:expense, :prior_month, envelope: envelope, user: member) }

      before { sign_in(member) }

      it "redirects with not authorized" do
        delete envelope_expense_path(envelope, expense)
        expect(response).to redirect_to(root_path)
        expect(expense.reload).to be_persisted
      end
    end

    context "prior month expense, owner" do
      let(:expense) { create(:expense, :prior_month, envelope: envelope, user: member) }

      before { sign_in(owner) }

      it "allows deletion" do
        delete envelope_expense_path(envelope, expense)
        expect { expense.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "current month expense, member" do
      let(:expense) { create(:expense, envelope: envelope, user: member) }

      before { sign_in(member) }

      it "allows deletion" do
        delete envelope_expense_path(envelope, expense)
        expect { expense.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
