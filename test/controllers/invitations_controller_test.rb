require "test_helper"

class InvitationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user     = users(:one)
    @inactive = users(:inactive)
    @pending  = invitations(:pending_one)
    @expired  = invitations(:expired_one)
  end

  # --- show (/i/:code) ---

  test "show: 비로그인 + 유효 코드 → 세션 저장 후 로그인 페이지" do
    get invitation_url_path(code: @pending.code)
    assert_redirected_to new_session_path
    assert_equal @pending.code, session[:pending_invitation_code]
  end

  test "show: 비로그인 + 만료 코드 → root + alert" do
    get invitation_url_path(code: @expired.code)
    assert_redirected_to root_path
    assert_match(/유효하지 않/, flash[:alert])
  end

  test "show: 로그인 + 비활성 → 코드 자동 적용" do
    sign_in_as(@inactive)
    get invitation_url_path(code: @pending.code)
    assert_redirected_to root_path
    assert @inactive.reload.active?
    assert @pending.reload.accepted?
  end

  test "show: 로그인 + 활성 → 안내만" do
    sign_in_as(@user)
    get invitation_url_path(code: @pending.code)
    assert_redirected_to root_path
    assert @pending.reload.pending?
  end

  # --- redeem 폼 + 적용 ---

  test "redeem 폼: 비활성 사용자 접근 가능" do
    sign_in_as(@inactive)
    get redeem_invitations_path
    assert_response :success
  end

  test "apply_redemption: 유효 코드 → 활성화" do
    sign_in_as(@inactive)
    post apply_redemption_invitations_path, params: { code: @pending.code }
    assert_redirected_to root_path
    assert @inactive.reload.active?
  end

  test "apply_redemption: 소문자 입력도 정규화" do
    sign_in_as(@inactive)
    post apply_redemption_invitations_path, params: { code: @pending.code.downcase }
    assert_redirected_to root_path
    assert @inactive.reload.active?
  end

  test "apply_redemption: 만료 코드 → 422" do
    sign_in_as(@inactive)
    post apply_redemption_invitations_path, params: { code: @expired.code }
    assert_response :unprocessable_entity
    assert_not @inactive.reload.active?
  end

  # --- create / destroy ---

  test "create: 7일 이내 발급 이력 있으면 거절" do
    sign_in_as(@user) # users(:one)은 pending_one을 방금 발급한 것으로 침
    assert_no_difference "Invitation.count" do
      post invitations_path, params: { invitation: { recommendation_comment: "테스트" } }
    end
    assert_redirected_to invitations_path
    assert_match(/무료 초대/, flash[:alert])
  end

  test "create: 7일 초과 사용자는 발급 성공" do
    sign_in_as(users(:two)) # 발급 이력 없음
    assert_difference "Invitation.count", 1 do
      post invitations_path, params: { invitation: { recommendation_comment: "오래된 친구이며 신뢰합니다." } }
    end
    assert_redirected_to invitations_path
  end

  test "create: boosted 옵션 시 크레딧 차감 + invitation.boosted=true" do
    user = users(:two)
    user.credit_transactions.create!(amount: 100, kind: :admin_grant, memo: "seed")
    sign_in_as(user)

    cost = Rails.application.config.x.blackticket.boosted_invitation_cost
    before = user.reload.ticket_credits

    post invitations_path, params: {
      invitation: { recommendation_comment: "강력 추천하는 동료입니다.", boosted: "1" }
    }
    inv = user.sent_invitations.order(:created_at).last
    assert inv.boosted?
    assert_equal before - cost, user.reload.ticket_credits
  end

  test "create: boosted인데 크레딧 부족 시 거절" do
    user = users(:two) # 보너스 받은 적 없는 fixture라 크레딧 0
    sign_in_as(user)
    assert_no_difference "Invitation.count" do
      post invitations_path, params: {
        invitation: { recommendation_comment: "강력 추천 시도.", boosted: "1" }
      }
    end
    assert_match(/크레딧/, flash[:alert])
  end

  test "create: recommendation_comment 누락 시 거절" do
    sign_in_as(users(:two))
    assert_no_difference "Invitation.count" do
      post invitations_path, params: { invitation: { recommendation_comment: "" } }
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
    # 통합 테스트에서 RecordNotFound는 404로 변환됨.
    assert_response :not_found
    assert @pending.reload.pending?
  end

  # --- 잠금 사용자가 다른 페이지 접근 시 redeem으로 강제 이동 ---

  test "잠금 사용자: 프로필 접근 시 redeem으로 redirect" do
    sign_in_as(@inactive)
    get profile_path(@inactive)
    assert_redirected_to redeem_invitations_path
  end

  test "잠금 사용자: 로그아웃은 가능" do
    sign_in_as(@inactive)
    delete session_path
    assert_redirected_to new_session_path
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
