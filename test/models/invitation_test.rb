require "test_helper"

class InvitationTest < ActiveSupport::TestCase
  setup { @inviter = users(:one) }

  test "create: code/token/expires_at 자동 부여" do
    inv = @inviter.sent_invitations.create!
    assert_match(/\A[A-Z2-9]{8}\z/, inv.code)
    assert_equal inv.code, inv.token
    assert inv.expires_at > 11.hours.from_now
    assert inv.pending?
  end

  test "code unique 충돌 시 재시도" do
    existing = invitations(:pending_one).code
    # before_validation에서 회전하므로 새로 만든 invitation은 다른 code를 가짐
    inv = @inviter.sent_invitations.create!
    assert_not_equal existing, inv.code
  end

  test "usable? — pending + 미만료" do
    assert invitations(:pending_one).usable?
    assert_not invitations(:expired_one).usable?
    assert_not invitations(:accepted_one).usable?
  end

  test "redeem!: 사용자 활성화 + accepted_by 기록" do
    target = users(:inactive)
    inv = invitations(:pending_one)

    inv.redeem!(target)

    assert inv.reload.accepted?
    assert_equal target, inv.accepted_by
    assert target.reload.active?
    assert_equal @inviter, target.invited_by
  end

  test "cancel!" do
    inv = invitations(:pending_one)
    inv.cancel!
    assert inv.reload.cancelled?
  end
end
