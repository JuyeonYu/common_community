require "test_helper"

class EmailOtpTest < ActiveSupport::TestCase
  test "issue: 6자리 코드 생성 + TTL 적용" do
    otp = EmailOtp.issue("USER@EXAMPLE.com")
    assert_equal 6, otp.code.length
    assert_match(/\A\d{6}\z/, otp.code)
    assert_in_delta EmailOtp::TTL.from_now.to_f, otp.expires_at.to_f, 5.0
    assert_equal "user@example.com", otp.email
  end

  test "verify: 정상 코드는 true, consumed 처리" do
    otp = EmailOtp.issue("a@example.com")
    assert EmailOtp.verify(email: "a@example.com", code: otp.code)
    assert_not_nil otp.reload.consumed_at
  end

  test "verify: 잘못된 코드는 false" do
    EmailOtp.issue("a@example.com")
    assert_not EmailOtp.verify(email: "a@example.com", code: "000000")
  end

  test "verify: 동일 코드 두 번째 시도는 false" do
    otp = EmailOtp.issue("a@example.com")
    EmailOtp.verify(email: "a@example.com", code: otp.code)
    assert_not EmailOtp.verify(email: "a@example.com", code: otp.code)
  end

  test "verify: 만료된 코드는 false" do
    otp = EmailOtp.issue("a@example.com")
    otp.update_column(:expires_at, 1.minute.ago)
    assert_not EmailOtp.verify(email: "a@example.com", code: otp.code)
  end
end
