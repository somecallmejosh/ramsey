require "rails_helper"

RSpec.describe PasswordsMailer, type: :mailer do
  let(:user) { create(:user, email_address: "sam@example.com") }
  let(:mail) { described_class.reset(user) }

  it "addresses the user" do
    expect(mail.to).to eq([ "sam@example.com" ])
    expect(mail.subject).to eq("Reset your Clempo password")
  end

  [ :html_part, :text_part ].each do |part|
    it "has a greeting, link, expiry and reassurance in the #{part}" do
      body = mail.public_send(part).decoded
      expect(body).to include("Hi Sam,")
      expect(body).to include("http://example.com/passwords/")
      expect(body).to include("15 minutes")
      expect(body).to include("your password won")
    end
  end
end
