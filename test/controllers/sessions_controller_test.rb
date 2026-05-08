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

  test "Google OAuth 콜백: 신규 사용자 가입 + 로그인" do
    mock_google_auth(uid: "ctl-test-uid", email: "ctl@example.com", name: "컨트롤러테스트")

    assert_difference "User.count", 1 do
      get oauth_callback_path(provider: "google_oauth2"),
        env: { "omniauth.auth" => OmniAuth.config.mock_auth[:google_oauth2] }
    end

    assert_redirected_to root_path
    assert cookies[:session_id]
    assert_equal "ctl@example.com", User.find_by(google_uid: "ctl-test-uid").email_address
  end

  test "Google OAuth 콜백: 기존 사용자 재로그인" do
    User.from_google_oauth(OmniAuth::AuthHash.new(
      provider: "google_oauth2", uid: "repeat-uid",
      info: { email: "repeat@example.com", name: "재방문" }
    ))
    mock_google_auth(uid: "repeat-uid", email: "repeat@example.com", name: "재방문")

    assert_no_difference "User.count" do
      get oauth_callback_path(provider: "google_oauth2"),
        env: { "omniauth.auth" => OmniAuth.config.mock_auth[:google_oauth2] }
    end

    assert_redirected_to root_path
    assert cookies[:session_id]
  end

  test "Google OAuth 실패 처리" do
    get auth_failure_path, params: { message: "access_denied" }

    assert_redirected_to new_session_path
    assert_match(/실패/, flash[:alert])
  end
end
