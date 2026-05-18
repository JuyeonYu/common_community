require "test_helper"

class MatchingControllerTest < ActionDispatch::IntegrationTest
  setup { @user = users(:one) }

  test "show: 비로그인 차단" do
    get matching_path
    assert_redirected_to new_session_path
  end

  test "show: 프로필 미충족 사용자는 체크리스트" do
    sign_in_as(@user)
    get matching_path
    assert_response :success
    assert_match(/활성화 조건/, response.body)
  end

  test "enable: 프로필 미충족 시 거절" do
    sign_in_as(@user)
    post enable_matching_path
    assert_redirected_to matching_path
    assert_not @user.reload.matching_enabled?
  end

  test "enable: 프로필 충족 시 활성화" do
    fill_required_profile(@user)
    sign_in_as(@user)
    post enable_matching_path
    assert_redirected_to matching_path
    assert @user.reload.matching_enabled?
    assert_not_nil @user.matching_activated_at
  end

  test "destroy: 활성 사용자 일시 중지" do
    fill_required_profile(@user)
    @user.enable_matching!
    sign_in_as(@user)

    delete matching_path
    assert_redirected_to matching_path
    assert_not @user.reload.matching_enabled?
    assert_not_nil @user.matching_activated_at # 이력 보존
  end

  # --- 추가 매칭권 (Phase F-2-a) ---

  test "extend_pool: 활성 + 잔액 충분 → 풀 +5 카운트 + 크레딧 차감" do
    fill_required_profile(@user)
    @user.enable_matching!
    cost = Rails.application.config.x.blackticket.extra_matching_cost
    @user.credit_transactions.create!(amount: cost * 2, kind: :admin_grant, memo: "seed")
    sign_in_as(@user)
    before = @user.reload.ticket_credits

    post extend_pool_matching_path
    assert_redirected_to matching_path
    assert_equal before - cost, @user.reload.ticket_credits
    gw = ConnectRequest.current_gen_week
    assert_equal 1, @user.extra_matchings_this_week_count(gw)
  end

  test "extend_pool: 잔액 부족 거절" do
    fill_required_profile(@user)
    @user.enable_matching!
    sign_in_as(@user)
    post extend_pool_matching_path
    assert_match(/크레딧이 부족/, flash[:alert])
  end

  test "extend_pool: 비활성 사용자 거절" do
    sign_in_as(@user)
    post extend_pool_matching_path
    assert_match(/활성화되지 않/, flash[:alert])
  end

  # --- 새로고침 (Phase F-2-b) ---

  test "refresh: 활성 + 잔액 충분 → MatchExposure 삭제 + 크레딧 차감" do
    fill_required_profile(@user)
    @user.enable_matching!
    other = users(:two)
    MatchExposure.create!(viewer: @user, target: other)
    cost = Rails.application.config.x.blackticket.refresh_matching_cost
    @user.credit_transactions.create!(amount: cost * 2, kind: :admin_grant, memo: "seed")
    sign_in_as(@user)
    before = @user.reload.ticket_credits

    post refresh_matching_path
    assert_redirected_to matching_path
    assert_equal 0, MatchExposure.where(viewer_id: @user.id).count
    assert_equal before - cost, @user.reload.ticket_credits
  end

  test "refresh: 잔액 부족 거절" do
    fill_required_profile(@user)
    @user.enable_matching!
    sign_in_as(@user)
    post refresh_matching_path
    assert_match(/크레딧이 부족/, flash[:alert])
  end

  test "refresh: 비활성 사용자 거절" do
    sign_in_as(@user)
    post refresh_matching_path
    assert_match(/활성화되지 않/, flash[:alert])
  end

  # --- 추천 코멘트 강조 (Phase F-2-c) ---

  def fresh_invitation_with_rec(user)
    inv = users(:two).sent_invitations.create!(invitee_email: "rec-#{user.id}@gmail.com")
    inv.update!(status: :accepted, accepted_by: user,
                recommendation_comment: "잘 아는 동료입니다 (테스트용).")
    user.update!(invited_by: users(:two), invitation_accepted_at: Time.current, seed: false)
    inv
  end

  test "highlight_recommendation: 추천서 보유 + 잔액 충분 → 크레딧 차감 + 본 기수 1회 표시" do
    fresh_invitation_with_rec(@user)
    cost = Rails.application.config.x.blackticket.highlight_recommendation_cost
    @user.credit_transactions.create!(amount: cost * 2, kind: :admin_grant, memo: "seed")
    sign_in_as(@user)
    before = @user.reload.ticket_credits

    post highlight_recommendation_matching_path
    assert_equal before - cost, @user.reload.ticket_credits
    assert @user.highlight_purchased_this_week?(ConnectRequest.current_gen_week)
  end

  test "highlight_recommendation: 본 기수 중복 구매 거절" do
    fresh_invitation_with_rec(@user)
    cost = Rails.application.config.x.blackticket.highlight_recommendation_cost
    @user.credit_transactions.create!(amount: cost * 3, kind: :admin_grant, memo: "seed")
    @user.credit_transactions.create!(amount: -cost, kind: :spend, memo: "highlight_recommendation")
    sign_in_as(@user)
    before = @user.reload.ticket_credits

    post highlight_recommendation_matching_path
    assert_equal before, @user.reload.ticket_credits
    assert_match(/이미 강조 표시/, flash[:notice])
  end

  test "highlight_recommendation: 추천서 미작성이면 거절" do
    sign_in_as(@user)
    post highlight_recommendation_matching_path
    assert_match(/강조할 추천서/, flash[:alert])
  end

  # --- 필터 해제 (Phase F-2-c) ---

  test "unlock_filter: 활성 + 잔액 충분 → 본 기수 적용 + 크레딧 차감" do
    fill_required_profile(@user)
    @user.enable_matching!
    cost = Rails.application.config.x.blackticket.filter_unlock_cost
    @user.credit_transactions.create!(amount: cost * 2, kind: :admin_grant, memo: "seed")
    sign_in_as(@user)
    before = @user.reload.ticket_credits

    post unlock_filter_matching_path
    assert_equal before - cost, @user.reload.ticket_credits
    assert @user.filter_unlocked_this_week?(ConnectRequest.current_gen_week)
  end

  test "unlock_filter: 본 기수 중복 구매 거절" do
    fill_required_profile(@user)
    @user.enable_matching!
    cost = Rails.application.config.x.blackticket.filter_unlock_cost
    @user.credit_transactions.create!(amount: cost * 3, kind: :admin_grant, memo: "seed")
    @user.credit_transactions.create!(amount: -cost, kind: :spend, memo: "filter_unlock")
    sign_in_as(@user)
    before = @user.reload.ticket_credits

    post unlock_filter_matching_path
    assert_equal before, @user.reload.ticket_credits
    assert_match(/이미 필터 해제/, flash[:notice])
  end

  test "unlock_filter: 비활성 사용자 거절" do
    sign_in_as(@user)
    post unlock_filter_matching_path
    assert_match(/활성화되지 않/, flash[:alert])
  end

  # --- 프로필 우선 노출 (Phase F-2-c) ---

  test "boost_profile: 잔액 충분 → boosted_until 24h 후 + 크레딧 차감" do
    cost = Rails.application.config.x.blackticket.profile_boost_cost
    @user.credit_transactions.create!(amount: cost * 2, kind: :admin_grant, memo: "seed")
    sign_in_as(@user)
    before = @user.reload.ticket_credits

    post boost_profile_matching_path
    assert_equal before - cost, @user.reload.ticket_credits
    assert @user.profile_boosted?
    assert_in_delta 24.hours.from_now.to_i, @user.boosted_until.to_i, 10
  end

  test "boost_profile: 활성 중이면 안내" do
    @user.update!(boosted_until: 12.hours.from_now)
    sign_in_as(@user)
    assert_no_difference -> { @user.reload.ticket_credits } do
      post boost_profile_matching_path
    end
    assert_match(/우선 노출이/, flash[:notice])
  end

  test "boost_profile: 잔액 부족 거절" do
    sign_in_as(@user)
    post boost_profile_matching_path
    assert_match(/크레딧이 부족/, flash[:alert])
  end

  private
    def fill_required_profile(user)
      user.update!(
        nickname: "닉네임#{user.id}",
        birth_date: 30.years.ago.to_date,
        gender: :male,
        residence_area: :seoul,
        job_title: "개발자",
        smoking: :non_smoker,
        hobby: "러닝",
        bio: "안녕하세요"
      )
      file = Rack::Test::UploadedFile.new(StringIO.new("fake"), "image/png", original_filename: "a.png")
      user.avatar.attach(io: StringIO.new("png"), filename: "a.png", content_type: "image/png")
    end
end
