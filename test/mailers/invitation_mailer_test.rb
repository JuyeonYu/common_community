require "test_helper"

class InvitationMailerTest < ActionMailer::TestCase
  test "invite: 헤더 + 본문 (추천서 작성된 경우)" do
    inv  = invitations(:pending_one)
    mail = InvitationMailer.invite(inv)

    assert_equal [ inv.invitee_email ], mail.to
    assert_match(/블랙티켓/, mail.subject)
    text = mail.text_part.body.to_s
    html = mail.html_part.body.to_s
    assert_match(inv.recommendation_comment, text)
    assert_match(inv.code, text)
    assert_match(inv.recommendation_comment, html)
  end

  test "invite: 추천서 미작성이면 추천서 섹션 생략" do
    inv = users(:one).sent_invitations.create!(invitee_email: "no-rec@example.com")
    mail = InvitationMailer.invite(inv)
    text = mail.text_part.body.to_s
    html = mail.html_part.body.to_s
    assert_no_match(/초대자의 추천/, text)
    assert_match(inv.code, text)
    assert_match(inv.invitee_email, html)
  end

  test "default from: invitations@messageopen.com" do
    inv  = invitations(:pending_one)
    mail = InvitationMailer.invite(inv)
    assert_match(/invitations@messageopen\.com/, mail.from.first)
  end
end
