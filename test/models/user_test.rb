require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "이메일 strip + downcase" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "이메일 unique" do
    User.create!(email_address: "dup@example.com", name: "원본")
    dup = User.new(email_address: "dup@example.com", name: "복제")
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

  test "active?: 정지 중이면 false (시드라도)" do
    u = User.new(seed: true, suspended_until: 1.day.from_now)
    assert_not u.active?
  end

  test "active?: 정지 만료 후엔 true" do
    u = User.new(seed: true, suspended_until: 1.day.ago)
    assert u.active?
  end

  test "age 계산" do
    u = User.new(birth_date: 30.years.ago.to_date - 1.day)
    assert_equal 30, u.age
  end

  test "hobby 정규화: 콤마/공백 분리 + # prefix" do
    u = users(:one)
    u.update!(hobby: "러닝, 사진 컬처")
    assert_equal "#러닝 #사진 #컬처", u.reload.hobby
  end

  test "hobby 중복 제거" do
    u = users(:one)
    u.update!(hobby: "러닝 러닝, #사진")
    assert_equal "#러닝 #사진", u.reload.hobby
  end

  test "신규 가입자에게 signup_bonus 크레딧" do
    auth = OmniAuth::AuthHash.new(
      provider: "google_oauth2", uid: "bonus-uid",
      info: { email: "bonus@example.com", name: "보너스" }
    )
    user = User.from_google_oauth(auth)
    expected = Rails.application.config.x.blackticket.signup_bonus_credits
    assert_equal expected, user.reload.ticket_credits
    assert user.credit_transactions.exists?(kind: :signup_bonus)
  end

  test "닉네임 unique" do
    User.create!(email_address: "n1@example.com", name: "유저1", nickname: "동일닉")
    dup = User.new(email_address: "n2@example.com", name: "유저2", nickname: "동일닉")
    assert_not dup.valid?
    assert_includes dup.errors.attribute_names, :nickname
  end

  test "닉네임 format" do
    u = User.new(email_address: "f@example.com", name: "포맷", nickname: "공백 안돼")
    assert_not u.valid?
    assert_includes u.errors.attribute_names, :nickname
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

  # --- 본인인증 (Phase I-2) ---

  test "identity_verified?: seed 사용자는 면제" do
    u = User.new(seed: true)
    assert u.identity_verified?
  end

  test "identity_verified?: identity_verified_at 있어야 true" do
    u = User.new(seed: false)
    assert_not u.identity_verified?
    u.identity_verified_at = Time.current
    assert u.identity_verified?
  end

  test "CI unique 강제" do
    User.create!(email_address: "ci1@example.com", name: "본인1", ci: "CI_ABC123")
    dup = User.new(email_address: "ci2@example.com", name: "본인2", ci: "CI_ABC123")
    assert_not dup.valid?
    assert_includes dup.errors.attribute_names, :ci
  end
end
