class OtpMailer < ApplicationMailer
  default from: "noreply@blackticket.example"

  def otp_email(email, code)
    @code = code
    mail to: email, subject: "[Black Ticket] 인증 코드 #{code}"
  end
end
