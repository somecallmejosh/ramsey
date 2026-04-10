require "rails_helper"

RSpec.describe "Admin::Accounts", type: :request do
  let(:account) { create(:account) }
  let(:owner)   { create(:user, :owner, account: account) }
  let(:member)  { create(:user, account: account) }

  describe "GET /admin/account/export" do
    context "owner" do
      before { sign_in(owner) }

      it "downloads a CSV file" do
        get export_admin_account_path
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include("text/csv")
        expect(response.headers["Content-Disposition"]).to include(".csv")
      end

      it "includes account data in the CSV" do
        create(:envelope, account: account, name: "Groceries")
        get export_admin_account_path
        expect(response.body).to include("Groceries")
      end
    end

    context "member" do
      before { sign_in(member) }

      it "redirects to root" do
        get export_admin_account_path
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "DELETE /admin/account" do
    context "owner" do
      before { sign_in(owner) }

      it "destroys the account and redirects to login" do
        delete admin_account_path
        expect(response).to redirect_to(new_session_path)
        expect(Account.find_by(id: account.id)).to be_nil
      end

      it "destroys all associated data" do
        create(:envelope, account: account)
        create(:debt, account: account)
        delete admin_account_path
        expect(Envelope.where(account_id: account.id)).to be_empty
        expect(Debt.where(account_id: account.id)).to be_empty
      end
    end

    context "member" do
      before { sign_in(member) }

      it "redirects to root" do
        delete admin_account_path
        expect(response).to redirect_to(root_path)
        expect(Account.find_by(id: account.id)).to be_present
      end
    end
  end
end
