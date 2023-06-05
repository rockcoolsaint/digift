class ApplicationMailer < ActionMailer::Base
  default from: "Sandra from DIGIFT <#{ENV['MAIL_FROM']}>"
  layout 'mailer'
end
