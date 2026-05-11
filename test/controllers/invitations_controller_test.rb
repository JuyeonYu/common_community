require "test_helper"

class InvitationsControllerTest < ActionDispatch::IntegrationTest
  test "index: 비로그인 차단" do
    get invitations_path
    assert_redirected_to new_session_path
  end

  test "index: 본인 보낸 초대 목록" do
    sign_in_as(users(:one))
    get invitations_path
    assert_response :success
  end

  test "create: 초대 발송 + 메일 1건" do
    sign_in_as(users(:one))
    assert_difference "Invitation.count", 1 do
      assert_emails 1 do
        post invitations_path, params: {
          invitation: { invitee_name: "친구", invitee_phone: "01099991111", invitee_email: "friend@example.com" }
        }
      end
    end
  end

  test "destroy: 본인 초대만 취소 가능" do
    sign_in_as(users(:one))
    inv = invitations(:active_invitation)
    delete invitation_path(inv)
    assert_redirected_to invitations_path
    assert_not_nil inv.reload.canceled_at
  end

  test "destroy: 다른 사람 초대는 404" do
    sign_in_as(users(:two))
    inv = invitations(:active_invitation)
    delete invitation_path(inv)
    assert_response :not_found
    assert_not_nil inv.reload
    assert_nil inv.canceled_at
  end
end
