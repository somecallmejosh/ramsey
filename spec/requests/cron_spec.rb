require "rails_helper"

RSpec.describe "Cron", type: :request do
  let(:cron_secret) { "test-cron-secret-abc123" }

  before do
    allow(Rails.application.credentials).to receive(:cron_secret).and_return(cron_secret)
  end

  describe "POST /cron/monthly_rollover" do
    context "with no Authorization header" do
      it "returns 401" do
        post cron_monthly_rollover_path
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with wrong token" do
      it "returns 401" do
        post cron_monthly_rollover_path, headers: { "Authorization" => "Bearer wrong-token" }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with correct token" do
      it "returns 200 and enqueues MonthlyRolloverJob" do
        expect {
          post cron_monthly_rollover_path, headers: { "Authorization" => "Bearer #{cron_secret}" }
        }.to have_enqueued_job(MonthlyRolloverJob)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "POST /cron/purge_unconfirmed_meal_plans" do
    context "with correct token" do
      it "returns 200 and enqueues PurgeUnconfirmedMealPlansJob" do
        expect {
          post cron_purge_meal_plans_path, headers: { "Authorization" => "Bearer #{cron_secret}" }
        }.to have_enqueued_job(PurgeUnconfirmedMealPlansJob)
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
