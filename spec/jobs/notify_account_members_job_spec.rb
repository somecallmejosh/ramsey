require "rails_helper"

RSpec.describe NotifyAccountMembersJob, type: :job do
  let(:account)  { create(:account) }
  let(:josh)     { create(:user, account: account) }
  let(:sally)    { create(:user, account: account) }
  let(:envelope) { create(:envelope, account: account, name: "Groceries") }
  let!(:budget)  { create(:envelope_budget, envelope: envelope,
                          year: Date.current.year, month: Date.current.month, amount: 700) }
  let(:expense)  { create(:expense, user: josh, envelope: envelope,
                          amount: 47.23, transacted_on: Date.current) }
  let!(:sally_sub) { create(:push_subscription, user: sally) }
  let!(:josh_sub)  { create(:push_subscription, user: josh) }
  let(:vapid) { { subject: "mailto:test@example.com", vapid_public_key: "pub", vapid_private_key: "priv" } }

  before do
    allow(Rails.application.credentials).to receive(:push_notifications).and_return(vapid)
    allow(WebPush).to receive(:payload_send)
  end

  def sent_to(subscription)
    sent = []
    expect(WebPush).to have_received(:payload_send).at_least(:once) do |args|
      sent << JSON.parse(args[:message]) if args[:endpoint] == subscription.endpoint
    end
    sent
  end

  describe "expense notification" do
    it "notifies the rest of the household, with the category page to open" do
      described_class.perform_now("Expense", expense.id)

      payload = sent_to(sally_sub).sole
      expect(payload["title"]).to include("Groceries")
      expect(payload["title"]).to include("$47.23")
      expect(payload["url"]).to start_with("/envelopes/#{envelope.id}/expenses")
      expect(payload["icon"]).to eq("/web-app-manifest-192x192.png")
      expect(payload["badge"]).to eq("/notification-badge.png")
    end

    it "doesn't tell the person who logged it about their own ordinary purchase" do
      described_class.perform_now("Expense", expense.id)
      expect(WebPush).not_to have_received(:payload_send).with(hash_including(endpoint: josh_sub.endpoint))
    end

    it "alerts everyone, including the person who logged it, when the category goes over" do
      create(:expense, user: sally, envelope: envelope, amount: 690, transacted_on: Date.current)
      described_class.perform_now("Expense", expense.id)

      expect(sent_to(sally_sub).sole["title"]).to eq("Groceries is over budget")
      expect(sent_to(josh_sub).sole["body"]).to start_with("You logged $47.23.")
    end

    it "no-ops when the resource no longer exists" do
      expect { described_class.perform_now("Expense", 0) }.not_to raise_error
      expect(WebPush).not_to have_received(:payload_send)
    end

    it "no-ops when no other account members are subscribed" do
      sally_sub.destroy
      described_class.perform_now("Expense", expense.id)
      expect(WebPush).not_to have_received(:payload_send)
    end

    it "never reaches people in another household" do
      outsider_sub = create(:push_subscription, user: create(:user, account: create(:account)))
      described_class.perform_now("Expense", expense.id)
      expect(WebPush).not_to have_received(:payload_send).with(hash_including(endpoint: outsider_sub.endpoint))
    end

    it "skips quietly when VAPID keys aren't configured" do
      allow(Rails.application.credentials).to receive(:push_notifications).and_return(nil)
      expect { described_class.perform_now("Expense", expense.id) }.not_to raise_error
      expect(WebPush).not_to have_received(:payload_send)
    end
  end

  describe "lunch log notification" do
    let!(:log) { create(:lunch_log, user: josh, logged_on: Date.current) }

    it "tells the rest of the household lunch was packed" do
      described_class.perform_now("LunchLog", log.id)
      expect(sent_to(sally_sub).sole["body"]).to include("packed lunch")
    end
  end

  it "refuses resource types it doesn't know" do
    expect { described_class.perform_now("User", josh.id) }.to raise_error(KeyError)
  end

  describe "delivery failures" do
    it "destroys an expired subscription and does not raise" do
      allow(WebPush).to receive(:payload_send).and_raise(WebPush::ExpiredSubscription.allocate)
      expect {
        described_class.perform_now("Expense", expense.id)
      }.to change { sally.push_subscriptions.count }.by(-1)
    end

    it "destroys an invalid subscription and does not raise" do
      allow(WebPush).to receive(:payload_send).and_raise(WebPush::InvalidSubscription.allocate)
      expect {
        described_class.perform_now("Expense", expense.id)
      }.to change { sally.push_subscriptions.count }.by(-1)
    end

    it "keeps going past a push service error so nobody is re-notified on retry" do
      third_sub = create(:push_subscription, user: create(:user, account: account))
      allow(WebPush).to receive(:payload_send).with(hash_including(endpoint: sally_sub.endpoint))
        .and_raise(WebPush::PushServiceError.allocate)

      expect { described_class.perform_now("Expense", expense.id) }.not_to raise_error
      expect(WebPush).to have_received(:payload_send).with(hash_including(endpoint: third_sub.endpoint))
      expect(sally.push_subscriptions.count).to eq(1)
    end
  end
end
