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
      post invitations_path, params: { invitation: { recommendation_comment: "환영" } }
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
end
