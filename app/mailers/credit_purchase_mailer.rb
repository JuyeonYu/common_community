class CreditPurchaseMailer < ApplicationMailer
  # 입금 알리기 접수 시 모든 admin에게 BCC로 발송.
  # to는 발신자(default from) 자체 — 운영자가 답장 시 사용자가 아닌 운영팀에 갈 수 있게 단순화.
  def notify_admins(purchase)
    @purchase = purchase
    @user     = purchase.user
    @admin_url = admin_credit_purchases_url

    admin_emails = User.where(admin: true).pluck(:email_address)

    mail(
      to:  default_params[:from],
      bcc: admin_emails,
      subject: "[블랙티켓] 입금 알리기 — #{purchase.declared_name} #{number_with_delimiter(purchase.declared_amount)}원"
    )
  end
end
