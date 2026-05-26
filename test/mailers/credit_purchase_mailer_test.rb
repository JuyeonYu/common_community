require "test_helper"

class CreditPurchaseMailerTest < ActionMailer::TestCase
  test "notify_admins: bcc는 모든 admin" do
    user = users(:one)
    p = user.credit_purchases.create!(package_key: "starter", declared_amount: 4900, declared_name: "유주연")
    mail = CreditPurchaseMailer.notify_admins(p)

    assert_match(/입금 알리기/, mail.subject)
    assert_match(/유주연/, mail.subject)
    bcc = Array(mail.bcc)
    User.where(admin: true).pluck(:email_address).each do |addr|
      assert_includes bcc, addr
    end
    body = mail.text_part.body.to_s
    assert_match(p.user.nickname, body)
    assert_match("스타터", body)
  end
end
