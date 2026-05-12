require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "이메일 strip + downcase" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "이메일 unique" do
    User.create!(email_address: "dup@example.com", name: "원본", password: "secret123")
    dup = User.new(email_address: "dup@example.com", name: "복제", password: "secret123")
    assert_not dup.valid?
    assert_includes dup.errors.attribute_names, :email_address
  end

  test "active?: seed=true 면 활성" do
    u = User.new(seed: true)
    assert u.active?
  end

  test "active?: invitation_accepted_at 있으면 활성" do
    u = User.new(invitation_accepted_at: Time.current)
    assert u.active?
  end

  test "active?: 둘 다 없으면 비활성" do
    u = User.new
    assert_not u.active?
  end

  test "from_google_oauth: 신규 + 시드 화이트리스트 → 자동 활성화" do
    auth = OmniAuth::AuthHash.new(
      provider: "google_oauth2", uid: "seed-uid",
      info: { email: seed_emails(:founder).email, name: "시드유저" }
    )

    assert_difference "User.count", 1 do
      user = User.from_google_oauth(auth)
      assert user.seed?
      assert user.invitation_accepted_at.present?
      assert user.active?
    end
  end

  test "from_google_oauth: 신규 + 일반 이메일 → 비활성" do
    auth = OmniAuth::AuthHash.new(
      provider: "google_oauth2", uid: "regular-uid",
      info: { email: "regular@example.com", name: "일반유저" }
    )
    user = User.from_google_oauth(auth)
    assert_not user.seed?
    assert_nil user.invitation_accepted_at
    assert_not user.active?
  end

  test "from_google_oauth: 동일 uid 재로그인 시 동일 사용자 반환, 상태 불변" do
    auth = OmniAuth::AuthHash.new(
      provider: "google_oauth2", uid: "repeat-uid",
      info: { email: "repeat@example.com", name: "재방문" }
    )
    first = User.from_google_oauth(auth)
    assert_no_difference "User.count" do
      again = User.from_google_oauth(auth)
      assert_equal first.id, again.id
    end
  end
end
