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
      let(:expense) { create(:expense, :prior_month, envelope: envelope, user: member, created_at: 1.hour.ago) }

      before { sign_in(member) }

      it "explains why and keeps the purchase" do
        delete envelope_expense_path(envelope, expense)
        expect(response).to redirect_to(envelope_expenses_path(envelope))
        expect(flash[:alert]).to include("past months")
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

  describe "POST /envelopes/:envelope_id/expenses (turbo stream)" do
    before do
      create(:envelope_budget, envelope: envelope, year: Date.current.year, month: Date.current.month, amount: 100)
      sign_in(member)
    end

    it "saves and streams the updated row, summary, recent list and an Undo toast" do
      expect {
        post envelope_expenses_path(envelope), params: { expense: { amount: "12.50", transacted_on: Date.current.iso8601 } }, as: :turbo_stream
      }.to change(Expense, :count).by(1)

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      body = response.body
      expect(body).to include(%(target="row_envelope_#{envelope.id}"))
      expect(body).to include(%(target="month-summary"))
      expect(body).to include(%(target="recent-expenses"))
      expect(body).to include("Saved $12.50 to #{envelope.name}")
      expect(body).to include("$87.50 left")
      expect(body).to include("Undo")
    end

    it "lets the rest of the household know" do
      post envelope_expenses_path(envelope), params: { expense: { amount: "12.50", transacted_on: Date.current.iso8601 } }, as: :turbo_stream
      expect(NotifyAccountMembersJob).to have_been_enqueued.with("Expense", Expense.last.id)
    end

    it "doesn't notify anyone when the purchase isn't saved" do
      post envelope_expenses_path(envelope), params: { expense: { amount: "" } }, as: :turbo_stream
      expect(NotifyAccountMembersJob).not_to have_been_enqueued
    end

    it "streams a readable error and keeps the expense unsaved" do
      post envelope_expenses_path(envelope), params: { expense: { amount: "5", transacted_on: (Date.current + 2).iso8601 } }, as: :turbo_stream

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include(%(target="logger-error"))
      expect(response.body).to include("Date can&#39;t be in the future")
    end
  end

  describe "category history page" do
    before { sign_in(member) }

    it "lists purchases with a heading, weekly breakdown and month arrows" do
      create(:expense, envelope: envelope, user: member, amount: 42.5, transacted_on: Date.current)
      get envelope_expenses_path(envelope)
      expect(response.body).to include("Purchases")
      expect(response.body).to include("By week")
      expect(response.body).to include("Previous month")
      expect(response.body).to include("$42.50")
    end

    it "shows an empty state for a month with nothing logged" do
      get envelope_expenses_path(envelope)
      expect(response.body).to include("Nothing logged in #{Date.current.strftime("%B")}")
    end

    it "ignores a future month" do
      get envelope_expenses_path(envelope, year: Date.current.year + 1, month: 1)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(Date.current.strftime("%B %Y"))
    end
  end

  describe "delete then Undo (turbo stream)" do
    let!(:expense) { create(:expense, envelope: envelope, user: member, amount: 12.34, note: "Milk", transacted_on: Date.current) }

    before { sign_in(member) }

    it "refreshes the month and offers Undo, which puts the purchase back as it was" do
      delete envelope_expense_path(envelope, expense), as: :turbo_stream
      expect(response.body).to include(%(target="envelope-month"))
      expect(response.body).to include("Undo")
      token = response.body[/name="token" value="([^"]+)"/, 1]
      expect(token).to be_present

      expect {
        post restore_envelope_expenses_path(envelope), params: { token: CGI.unescapeHTML(token) }, as: :turbo_stream
      }.to change(Expense, :count).by(1)
      expect(NotifyAccountMembersJob).not_to have_been_enqueued

      restored = Expense.last
      expect(restored).to have_attributes(user_id: member.id, note: "Milk", amount: 12.34, transacted_on: Date.current)
      expect(restored.created_at).to eq(expense.created_at)
      expect(response.body).to include("Put back $12.34")
    end

    it "rejects a forged or foreign token" do
      other = create(:envelope, account: account)
      token = expense.restore_token
      post restore_envelope_expenses_path(other), params: { token: token }
      expect(response).to redirect_to(envelope_expenses_path(other))
      post restore_envelope_expenses_path(envelope), params: { token: "nope" }
      expect(flash[:alert]).to include("can't be put back")
    end
  end
end
