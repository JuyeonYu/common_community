require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @invitation = invitations(:active_invitation)
  end

  test "new: 유효한 토큰이면 폼 표시" do
    get signup_path(token: @invitation.token)
    assert_response :success
    assert_match(/Black Ticket 가입/, response.body)
  end

  test "new: 잘못된 토큰은 root로 redirect + alert" do
    get signup_path(token: "invalid")
    assert_redirected_to root_path
  end

  test "create: 만 25세 미만은 422" do
    post signup_path(token: @invitation.token), params: {
      user: { name: "신규", birthdate: 10.years.ago.to_date.to_s,
              phone: "01011112222", email_address: "invitee@example.com" }
    }
    assert_response :unprocessable_entity
    assert_match(/만 25세/, response.body + flash[:alert].to_s)
  end

  test "create: 블랙리스트 매칭 시 거부" do
    post signup_path(token: @invitation.token), params: {
      user: { name: "스팸유저", birthdate: 30.years.ago.to_date.to_s,
              phone: "010-9999-8888", email_address: "invitee@example.com" }
    }
    assert_redirected_to root_path
  end

  test "create: 정상 입력은 verify 화면으로 + OTP 발송" do
    assert_emails 1 do
      post signup_path(token: @invitation.token), params: {
        user: { name: "신규", birthdate: 30.years.ago.to_date.to_s,
                phone: "01011112222", email_address: "invitee@example.com" }
      }
    end
    assert_redirected_to verify_signup_path(token: @invitation.token)
  end

  test "confirm_otp: OTP 검증 + User 생성 + 자동 로그인 + 초대 accept" do
    # 먼저 create로 세션에 attrs 저장
    post signup_path(token: @invitation.token), params: {
      user: { name: "신규", birthdate: 30.years.ago.to_date.to_s,
              phone: "01011112222", email_address: "invitee@example.com" }
    }
    code = EmailOtp.for_email("invitee@example.com").last.code

    assert_difference "User.count", 1 do
      post confirm_signup_path(token: @invitation.token), params: { code: code }
    end
    assert_redirected_to root_path

    user = User.find_by(email_address: "invitee@example.com")
    assert_equal "신규", user.name
    assert_equal @invitation.inviter, user.inviter
    assert_not_nil @invitation.reload.accepted_at
    assert_equal user, @invitation.accepted_user
  end

  test "confirm_otp: 잘못된 코드는 verify 화면 alert" do
    post signup_path(token: @invitation.token), params: {
      user: { name: "신규", birthdate: 30.years.ago.to_date.to_s,
              phone: "01011112222", email_address: "invitee@example.com" }
    }
    post confirm_signup_path(token: @invitation.token), params: { code: "000000" }
    assert_redirected_to verify_signup_path(token: @invitation.token)
  end
end
