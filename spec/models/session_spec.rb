require "rails_helper"

RSpec.describe Session, type: :model do
  let(:user) { create(:user) }

  it "stays signed in across a few days away" do
    expect(user.sessions.create!(last_active_at: 10.days.ago)).not_to be_idle_expired
  end

  it "expires after the idle timeout" do
    expect(user.sessions.create!(last_active_at: (Session::IDLE_TIMEOUT + 1.day).ago)).to be_idle_expired
  end
end
