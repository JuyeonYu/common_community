require "test_helper"

class InvitationTest < ActiveSupport::TestCase
  setup { @inviter = users(:one) }

  def build_invite(**overrides)
    @inviter.sent_invitations.create!({
      invitee_email: "fresh-#{SecureRandom.hex(4)}@gmail.com"
    }.merge(overrides))
  end

  test "create: code/token/expires_at 자동 부여" do
    inv = build_invite
    assert_match(/\A[A-Z2-9]{8}\z/, inv.code)
    assert_equal inv.code, inv.token
    assert inv.expires_at > 11.hours.from_now
    assert inv.pending?
  end

  test "code unique 충돌 시 재시도" do
    existing = invitations(:pending_one).code
    inv = build_invite
    assert_not_equal existing, inv.code
  end

  test "usable? — pending + 미만료" do
    assert invitations(:pending_one).usable?
    assert_not invitations(:expired_one).usable?
    assert_not invitations(:accepted_one).usable?
  end

  test "redeem!: 이메일 일치 시 사용자 활성화 + accepted_by 기록" do
    inv = invitations(:pending_one)
    target = users(:inactive)
    target.update!(email_address: inv.invitee_email)

    inv.redeem!(target)

    assert inv.reload.accepted?
    assert_equal target, inv.accepted_by
    assert target.reload.active?
    assert_equal @inviter, target.invited_by
  end

  test "redeem!: 이메일 불일치 시 EmailMismatch" do
    inv = invitations(:pending_one)
    target = users(:inactive) # 다른 이메일
    assert_raises(Invitation::EmailMismatch) { inv.redeem!(target) }
  end

  test "cancel!" do
    inv = invitations(:pending_one)
    inv.cancel!
    assert inv.reload.cancelled?
  end

  test "recommendation_comment: 발급 시 빈 상태 허용" do
    inv = build_invite
    assert inv.valid?
    assert_not inv.recommendation_written?
  end

  test "recommendation_comment: 너무 짧으면 거절" do
    inv = @inviter.sent_invitations.build(
      recommendation_comment: "짧음",
      invitee_email: "short@gmail.com"
    )
    assert_not inv.valid?
    assert_includes inv.errors.attribute_names, :recommendation_comment
  end

  test "recommendation_comment: 첫 작성은 허용 (빈 → 값)" do
    inv = build_invite
    inv.recommendation_comment = "처음 작성하는 추천서입니다."
    assert inv.valid?
  end

  test "recommendation_comment: 사후 수정 거절 (값 → 다른값)" do
    inv = invitations(:pending_one)
    inv.recommendation_comment = "수정 시도하는 새로운 추천서"
    assert_not inv.valid?
    assert_includes inv.errors[:recommendation_comment].first, "수정할 수 없습니다"
  end

  test "invitee_email 필수 + format + normalize" do
    inv = @inviter.sent_invitations.build
    assert_not inv.valid?
    assert_includes inv.errors.attribute_names, :invitee_email

    inv.invitee_email = "  TEST@Gmail.Com  "
    assert_equal "test@gmail.com", inv.invitee_email
  end

  test "invitee_email: @gmail.com이 아니면 거절" do
    inv = @inviter.sent_invitations.build(invitee_email: "x@example.com")
    assert_not inv.valid?
    assert_includes inv.errors[:invitee_email].first, "@gmail.com"
  end

  test "이미 가입된 이메일로 초대 발급 거절" do
    existing = users(:one) # email_address = "one@example.com"
    inv = @inviter.sent_invitations.build(
      invitee_email: existing.email_address.upcase
    )
    assert_not inv.valid?
    assert_includes inv.errors.attribute_names, :invitee_email
  end

  test "matches_email?: 대소문자 무시" do
    inv = invitations(:pending_one)
    assert inv.matches_email?(inv.invitee_email.upcase)
    assert_not inv.matches_email?("other@example.com")
  end
end
