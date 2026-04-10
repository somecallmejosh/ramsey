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

  before do
    allow(WebPush).to receive(:payload_send)
  end

  describe "expense notification" do
    it "sends a push to account members' subscriptions" do
      described_class.perform_now("Expense", expense.id)
      expect(WebPush).to have_received(:payload_send)
        .with(hash_including(endpoint: sally_sub.endpoint))
    end

    it "includes the envelope name and remaining balance in the body" do
      described_class.perform_now("Expense", expense.id)
      expect(WebPush).to have_received(:payload_send) do |args|
        payload = JSON.parse(args[:message])
        expect(payload["body"]).to include("Groceries")
        expect(payload["body"]).to include("$47.23")
      end
    end

    it "no-ops when the resource no longer exists" do
      expect { described_class.perform_now("Expense", 0) }.not_to raise_error
      expect(WebPush).not_to have_received(:payload_send)
    end

    it "no-ops when no other account members exist" do
      sally.destroy
      described_class.perform_now("Expense", expense.id)
      expect(WebPush).not_to have_received(:payload_send)
    end

    it "no-ops when account members have no subscriptions" do
      sally_sub.destroy
      described_class.perform_now("Expense", expense.id)
      expect(WebPush).not_to have_received(:payload_send)
    end
  end

  describe "lunch log notification" do
    let!(:log) { create(:lunch_log, user: josh, logged_on: Date.current) }

    it "sends a push to account members' subscriptions" do
      described_class.perform_now("LunchLog", log.id)
      expect(WebPush).to have_received(:payload_send)
        .with(hash_including(endpoint: sally_sub.endpoint))
    end

    it "includes 'packed lunch' in the body" do
      described_class.perform_now("LunchLog", log.id)
      expect(WebPush).to have_received(:payload_send) do |args|
        payload = JSON.parse(args[:message])
        expect(payload["body"]).to include("packed lunch")
      end
    end
  end

  describe "dead subscription handling" do
    it "destroys the subscription and does not raise on ExpiredSubscription" do
      allow(WebPush).to receive(:payload_send)
        .and_raise(WebPush::ExpiredSubscription.allocate)
      expect {
        described_class.perform_now("Expense", expense.id)
      }.to change { sally.push_subscriptions.count }.by(-1)
    end

    it "destroys the subscription and does not raise on InvalidSubscription" do
      allow(WebPush).to receive(:payload_send)
        .and_raise(WebPush::InvalidSubscription.allocate)
      expect {
        described_class.perform_now("Expense", expense.id)
      }.to change { sally.push_subscriptions.count }.by(-1)
    end
  end
end
