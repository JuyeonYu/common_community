require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "이메일 주소는 strip + downcase 됨" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "from_google_oauth: 신규 사용자 생성" do
    auth = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "new-google-uid",
      info: { email: "newbie@example.com", name: "신규유저", image: "https://example.com/a.jpg" }
    )

    assert_difference "User.count", 1 do
      user = User.from_google_oauth(auth)
      assert_equal "new-google-uid", user.google_uid
      assert_equal "newbie@example.com", user.email_address
      assert_equal "신규유저", user.name
      assert_equal "https://example.com/a.jpg", user.avatar_url
      assert_not user.admin?
    end
  end

  test "from_google_oauth: 동일 google_uid 재로그인 시 기존 사용자 반환" do
    auth = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "returning-uid",
      info: { email: "returning@example.com", name: "재방문", image: nil }
    )
    User.from_google_oauth(auth)

    assert_no_difference "User.count" do
      user = User.from_google_oauth(auth)
      assert_equal "returning-uid", user.google_uid
    end
  end

  test "from_google_oauth: 이름이 비면 이메일 앞부분으로 대체" do
    auth = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "no-name-uid",
      info: { email: "nameless@example.com", name: "", image: nil }
    )
    user = User.from_google_oauth(auth)
    assert_equal "nameless", user.name
  end
end
