require "test_helper"

class InvitationTest < ActiveSupport::TestCase
  setup { @inviter = users(:one) }

  test "create: token 자동 생성 + expires_at 12시간" do
    inv = Invitation.create!(inviter: @inviter, invitee_name: "친구", invitee_phone: "01000001111", invitee_email: "f@example.com")
    assert inv.token.present?
    assert_in_delta 12.hours.from_now.to_f, inv.expires_at.to_f, 5.0
  end

  test "status: active/expired/canceled/accepted" do
    inv = Invitation.create!(inviter: @inviter, invitee_name: "x", invitee_phone: "01000001111", invitee_email: "f@example.com")
    assert_equal :active, inv.status

    inv.update_column(:expires_at, 1.minute.ago)
    assert_equal :expired, inv.status

    inv.update!(expires_at: 1.day.from_now, canceled_at: Time.current)
    assert_equal :canceled, inv.status

    inv.update!(canceled_at: nil, accepted_at: Time.current)
    assert_equal :accepted, inv.status
  end

  test "cancel!: 미가입은 취소 가능, 가입된 건 거부" do
    inv = invitations(:active_invitation)
    assert inv.cancel!
    inv.update!(canceled_at: nil, accepted_at: Time.current)
    assert_not inv.cancel!
  end
end
