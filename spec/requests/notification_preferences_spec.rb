require "rails_helper"

RSpec.describe "NotificationPreferences", type: :request do
  let(:account) { create(:account) }
  let(:member)  { create(:user, account: account) }

  describe "PATCH /account/notifications" do
    it "redirects to sign in when signed out" do
      patch notification_preference_path, params: { notifications_enabled: "false" }
      expect(response).to redirect_to(new_session_path)
    end

    context "signed in as a member" do
      before { sign_in(member) }

      it "starts with notifications on" do
        expect(member.notifications_enabled).to be(true)
      end

      it "turns notifications off" do
        patch notification_preference_path, params: { notifications_enabled: "false" }
        expect(response).to redirect_to(admin_settings_path)
        expect(flash[:notice]).to eq("Notifications are off. You won't get any household alerts.")
        expect(member.reload.notifications_enabled).to be(false)
      end

      it "turns notifications back on" do
        member.update!(notifications_enabled: false)
        patch notification_preference_path, params: { notifications_enabled: "true" }
        expect(flash[:notice]).to eq("Notifications are on.")
        expect(member.reload.notifications_enabled).to be(true)
      end

      it "shows the current state and the opposite action on Settings" do
        get admin_settings_path
        expect(response.body).to include("Household alerts")
        expect(response.body).to include("Turn off")

        member.update!(notifications_enabled: false)
        get admin_settings_path
        expect(response.body).to include("Turn on")
        expect(response.body).to include('data-action="notification-setting#turnOn"')
      end

      it "stops the opt-in prompt from asking once opted out" do
        allow(Rails.application.credentials).to receive(:dig).and_call_original
        allow(Rails.application.credentials).to receive(:dig).with(:push_notifications, :vapid_public_key).and_return("pub")
        member.update!(notifications_enabled: false)

        get root_path
        expect(response.body).to include('data-push-notifications-opted-in-value="false"')
      end
    end
  end
end
