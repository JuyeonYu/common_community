require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = users(:one) }

  test "new 페이지 표시" do
    get new_session_path
    assert_response :success
  end

  test "로그아웃" do
    sign_in_as(@user)
    delete session_path
    assert_redirected_to new_session_path
    assert_empty cookies[:session_id]
  end

  test "OAuth 콜백: 시드 화이트리스트 → 신규 사용자 자동 활성화" do
    mock_google_auth(uid: "seed-ctl-uid", email: seed_emails(:founder).email, name: "시드유저")
    assert_difference "User.count", 1 do
      get oauth_callback_path(provider: "google_oauth2"),
        env: { "omniauth.auth" => OmniAuth.config.mock_auth[:google_oauth2] }
    end
    user = User.find_by(google_uid: "seed-ctl-uid")
    assert user.active?
  end

  test "OAuth 콜백: 세션 초대 코드 + 이메일 일치 → 자동 활성화" do
    inv = invitations(:pending_one)
    get invite_link_path(code: inv.code) # 비로그인 → 세션에 code + invitee_email 저장

    mock_google_auth(uid: "code-ctl-uid", email: inv.invitee_email, name: "초대받음")
    assert_difference "User.count", 1 do
      get oauth_callback_path(provider: "google_oauth2"),
        env: { "omniauth.auth" => OmniAuth.config.mock_auth[:google_oauth2] }
    end
    user = User.find_by(google_uid: "code-ctl-uid")
    assert user.active?
    assert inv.reload.accepted?
  end

  test "OAuth 콜백: 세션 초대 코드 + 이메일 불일치 → 가입 거절" do
    inv = invitations(:pending_one)
    get invite_link_path(code: inv.code) # 세션에 invitee_email 저장

    mock_google_auth(uid: "mismatch-uid", email: "different@example.com", name: "불일치")
    assert_no_difference "User.count" do
      get oauth_callback_path(provider: "google_oauth2"),
        env: { "omniauth.auth" => OmniAuth.config.mock_auth[:google_oauth2] }
    end
    assert_redirected_to new_session_path
    assert_match(/일치하지 않/, flash[:alert])
  end

  test "OAuth 콜백: 일반 이메일 + 세션 코드 없음 → 가입 거절" do
    mock_google_auth(uid: "plain-ctl-uid", email: "plain@example.com", name: "일반")
    assert_no_difference "User.count" do
      get oauth_callback_path(provider: "google_oauth2"),
        env: { "omniauth.auth" => OmniAuth.config.mock_auth[:google_oauth2] }
    end
    assert_redirected_to new_session_path
    assert_match(/초대를 받은 이메일로만/, flash[:alert])
  end

  test "OAuth 콜백: 기존 사용자 재로그인 (초대 없이)" do
    @user.update!(google_uid: "existing-uid")
    mock_google_auth(uid: "existing-uid", email: @user.email_address, name: @user.name)
    assert_no_difference "User.count" do
      get oauth_callback_path(provider: "google_oauth2"),
        env: { "omniauth.auth" => OmniAuth.config.mock_auth[:google_oauth2] }
    end
    assert_redirected_to root_path
  end

  test "Google OAuth 실패 처리" do
    get auth_failure_path, params: { message: "access_denied" }
    assert_redirected_to new_session_path
    assert_match(/실패/, flash[:alert])
  end
end
