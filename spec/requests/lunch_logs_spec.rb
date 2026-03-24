require "rails_helper"

RSpec.describe "LunchLogs", type: :request do
  let(:user)       { create(:user) }
  let(:other_user) { create(:user) }

  describe "GET /lunch_logs" do
    context "unauthenticated" do
      it "redirects to sign in" do
        get lunch_logs_path
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "authenticated" do
      before { sign_in(user) }

      it "returns 200" do
        get lunch_logs_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "POST /lunch_logs" do
    before { sign_in(user) }

    it "creates a log for current user" do
      expect {
        post lunch_logs_path, params: { logged_on: Date.current.to_s }
      }.to change { user.lunch_logs.count }.by(1)
    end

    it "ignores user_id param and always scopes to current_user" do
      post lunch_logs_path, params: { logged_on: Date.current.to_s, user_id: other_user.id }
      expect(LunchLog.last.user).to eq(user)
    end
  end

  describe "DELETE /lunch_logs/:id" do
    before { sign_in(user) }

    context "own log" do
      let!(:log) { create(:lunch_log, user: user, logged_on: Date.current) }

      it "deletes the record" do
        expect { delete lunch_log_path(log) }.to change { user.lunch_logs.count }.by(-1)
      end
    end

    context "another user's log" do
      let!(:other_log) { create(:lunch_log, user: other_user, logged_on: Date.current) }

      it "returns 404" do
        delete lunch_log_path(other_log)
        expect(response).to have_http_status(:not_found)
      end

      it "does not delete the record" do
        delete lunch_log_path(other_log)
        expect(other_log.reload).to be_persisted
      end
    end
  end
end
