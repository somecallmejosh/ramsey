class ApplicationMailer < ActionMailer::Base
  # Set MAILER_FROM in production to a real address on your domain, e.g.
  # "Clempo <hello@yourdomain.com>", so reset emails don't look like spam.
  default from: ENV.fetch("MAILER_FROM", "Clempo <no-reply@example.com>")
  layout "mailer"
end
