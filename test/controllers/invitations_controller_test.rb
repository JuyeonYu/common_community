require "test_helper"

class InvitationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user     = users(:one)
    @inactive = users(:inactive)
    @pending  = invitations(:pending_one)
    @expired  = invitations(:expired_one)
    # inactive 사용자의 이메일을 pending invitation에 맞춰 두면 redeem 매칭이 통과한다.
    @inactive.update!(email_address: @pending.invitee_email)
  end

  # --- show (/i/:code) ---

  test "show: 비로그인 + 유효 코드 → 세션 저장 후 로그인 페이지" do
    get invite_link_path(code: @pending.code)
    assert_redirected_to new_session_path
    assert_equal @pending.code, session[:pending_invitation_code]
    assert_equal @pending.invitee_email, session[:pending_invitee_email]
  end

  test "show: 비로그인 + 만료 코드 → root + alert" do
    get invite_link_path(code: @expired.code)
    assert_redirected_to root_path
    assert_match(/유효하지 않/, flash[:alert])
  end

  test "show: 로그인 + 활성 → 안내만" do
    sign_in_as(@user)
    get invite_link_path(code: @pending.code)
    assert_redirected_to root_path
    assert @pending.reload.pending?
  end

  # --- create / destroy ---

  test "create: 7일 이내 발급 이력 있으면 거절" do
    sign_in_as(@user)
    assert_no_difference "Invitation.count" do
      post invitations_path, params: { invitation: { invitee_email: "x@example.com", recommendation_comment: "테스트 추천서" } }
    end
    assert_redirected_to invitations_path
    assert_match(/무료 초대/, flash[:alert])
  end

  test "create: 7일 초과 사용자는 발급 성공 + 메일 잡 enqueue" do
    sign_in_as(users(:two))
    assert_difference "Invitation.count", 1 do
      assert_enqueued_jobs 1, only: InvitationMailJob do
        post invitations_path, params: {
          invitation: { invitee_email: "new-friend@example.com", recommendation_comment: "오래된 친구이며 신뢰합니다." }
        }
      end
    end
    assert_redirected_to invitations_path
  end

  test "create: invitee_email 누락 시 거절" do
    sign_in_as(users(:two))
    assert_no_difference "Invitation.count" do
      post invitations_path, params: { invitation: { recommendation_comment: "테스트 추천서입니다." } }
    end
    assert_redirected_to invitations_path
  end

  test "create: 이미 가입된 이메일은 거절" do
    sign_in_as(users(:two))
    assert_no_difference "Invitation.count" do
      post invitations_path, params: {
        invitation: { invitee_email: @user.email_address, recommendation_comment: "테스트 추천서입니다." }
      }
    end
  end

  test "create: boosted 옵션 시 크레딧 차감 + boosted=true" do
    user = users(:two)
    user.credit_transactions.create!(amount: 100, kind: :admin_grant, memo: "seed")
    sign_in_as(user)

    cost = Rails.application.config.x.blackticket.boosted_invitation_cost
    before = user.reload.ticket_credits

    post invitations_path, params: {
      invitation: { invitee_email: "boost@example.com", recommendation_comment: "강력 추천하는 동료입니다.", boosted: "1" }
    }
    inv = user.sent_invitations.order(:created_at).last
    assert inv.boosted?
    assert_equal before - cost, user.reload.ticket_credits
  end

  test "create: boosted인데 크레딧 부족 시 거절" do
    user = users(:two)
    sign_in_as(user)
    assert_no_difference "Invitation.count" do
      post invitations_path, params: {
        invitation: { invitee_email: "x@example.com", recommendation_comment: "강력 추천 시도하는 동료.", boosted: "1" }
      }
    end
    assert_match(/크레딧/, flash[:alert])
  end

  test "create: recommendation_comment 누락 시 거절" do
    sign_in_as(users(:two))
    assert_no_difference "Invitation.count" do
      post invitations_path, params: { invitation: { invitee_email: "x@example.com", recommendation_comment: "" } }
    end
    assert_redirected_to invitations_path
  end

  test "destroy: 본인 pending 초대 취소" do
    sign_in_as(@user)
    delete invitation_path(@pending)
    assert_redirected_to invitations_path
    assert @pending.reload.cancelled?
  end

  test "destroy: 남의 초대는 못 건드림" do
    sign_in_as(users(:two))
    delete invitation_path(@pending)
    assert_response :not_found
    assert @pending.reload.pending?
  end

  test "resend: pending+미만료 초대 재발송" do
    sign_in_as(@user)
    assert_enqueued_jobs 1, only: InvitationMailJob do
      post resend_invitation_path(@pending)
    end
    assert_redirected_to invitations_path
  end

  test "resend: 만료된 초대는 재발송 거절" do
    sign_in_as(@user)
    assert_no_enqueued_jobs only: InvitationMailJob do
      post resend_invitation_path(@expired)
    end
    assert_match(/재발송할 수 없/, flash[:alert])
  end

  # --- 비활성 사용자: 어떤 페이지든 접근 시 자동 로그아웃 ---

  test "비활성 사용자: 프로필 접근 시 자동 로그아웃 + 로그인 페이지로" do
    sign_in_as(@inactive)
    get profile_path(@inactive)
    assert_redirected_to new_session_path
    assert_empty cookies[:session_id]
  end

  test "비활성 사용자: 명시적 로그아웃도 동일하게 정리" do
    sign_in_as(@inactive)
    delete session_path
    assert_redirected_to new_session_path
    assert_empty cookies[:session_id]
  end

  test "index: 초대 트리 렌더 (본인 + invitees 노출)" do
    @inactive.update!(invited_by: @user, invitation_accepted_at: Time.current, seed: false)
    sign_in_as(@user)
    get invitations_path
    assert_response :success
    assert_match(/초대 트리/, response.body)
    assert_match(@inactive.name, response.body)
  end
end
