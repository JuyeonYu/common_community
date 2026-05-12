require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = users(:one) }

  test "new 페이지 표시" do
    get new_session_path
    assert_response :success
  end

  test "이메일/비밀번호 정상 로그인" do
    post session_path, params: { email_address: @user.email_address, password: "password" }

    assert_redirected_to root_path
    assert cookies[:session_id]
  end

  test "이메일/비밀번호 실패" do
    post session_path, params: { email_address: @user.email_address, password: "wrong" }

    assert_redirected_to new_session_path
    assert_nil cookies[:session_id]
  end

  test "로그아웃" do
    sign_in_as(@user)

    delete session_path

    assert_redirected_to new_session_path
    assert_empty cookies[:session_id]
  end

  test "Google OAuth 콜백: 시드 화이트리스트 → 신규 사용자 자동 활성화" do
    mock_google_auth(uid: "seed-ctl-uid", email: seed_emails(:founder).email, name: "시드유저")

    assert_difference "User.count", 1 do
      get oauth_callback_path(provider: "google_oauth2"),
        env: { "omniauth.auth" => OmniAuth.config.mock_auth[:google_oauth2] }
    end

    user = User.find_by(google_uid: "seed-ctl-uid")
    assert user.active?
  end

  test "Google OAuth 콜백: 세션 초대 코드 → 자동 활성화" do
    inv = invitations(:pending_one)
    # 세션에 코드를 박은 상태에서 OAuth 콜백이 호출됐다고 가정.
    # ActionDispatch::IntegrationTest는 직접 session 조작이 불가하므로 /i/:code → 콜백 흐름으로 검증.
    get invitation_url_path(code: inv.code) # → 비로그인이라 세션 저장 후 new_session_path

    mock_google_auth(uid: "code-ctl-uid", email: "invited@example.com", name: "초대받음")
    get oauth_callback_path(provider: "google_oauth2"),
      env: { "omniauth.auth" => OmniAuth.config.mock_auth[:google_oauth2] }

    user = User.find_by(google_uid: "code-ctl-uid")
    assert user.active?
    assert inv.reload.accepted?
  end

  test "Google OAuth 콜백: 일반 이메일 + 세션 코드 없음 → 비활성" do
    mock_google_auth(uid: "plain-ctl-uid", email: "plain@example.com", name: "일반")
    get oauth_callback_path(provider: "google_oauth2"),
      env: { "omniauth.auth" => OmniAuth.config.mock_auth[:google_oauth2] }

    user = User.find_by(google_uid: "plain-ctl-uid")
    assert_not user.active?
  end

  test "Google OAuth 실패 처리" do
    get auth_failure_path, params: { message: "access_denied" }
    assert_redirected_to new_session_path
    assert_match(/실패/, flash[:alert])
  end
end
