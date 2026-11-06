require "rails_helper"

RSpec.describe "Push subscriptions", type: :request do
  let(:account) { create(:account) }
  let(:josh)    { create(:user, account: account) }
  let(:sally)   { create(:user, account: account) }
  let(:params) do
    { subscription: { endpoint: "https://push.example/abc", keys: { auth: "a1", p256dh: "p1" } } }
  end

  it "requires sign in" do
    post push_subscriptions_path, params: params, as: :json
    expect(response).to redirect_to(new_session_path)
  end

  context "signed in" do
    before { sign_in(josh) }

    it "saves this device's subscription" do
      expect { post push_subscriptions_path, params: params, as: :json }.to change(josh.push_subscriptions, :count).by(1)
      expect(response).to have_http_status(:created)
      expect(josh.push_subscriptions.last).to have_attributes(endpoint: "https://push.example/abc", auth: "a1", p256dh: "p1")
    end

    it "is safe to send again (the browser re-syncs on every visit)" do
      2.times { post push_subscriptions_path, params: params, as: :json }
      expect(response).to have_http_status(:created)
      expect(PushSubscription.count).to eq(1)
    end

    it "moves a device's subscription to whoever is signed in on it now" do
      create(:push_subscription, user: sally, endpoint: "https://push.example/abc")
      post push_subscriptions_path, params: params, as: :json
      expect(PushSubscription.sole.user).to eq(josh)
    end

    it "rejects an incomplete subscription" do
      post push_subscriptions_path, params: { subscription: { endpoint: "https://push.example/abc" } }, as: :json
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "only lets you remove your own" do
      theirs = create(:push_subscription, user: sally)
      delete push_subscription_path(theirs)
      expect(response).to have_http_status(:not_found)
      expect(PushSubscription.exists?(theirs.id)).to be(true)
    end
  end
end
