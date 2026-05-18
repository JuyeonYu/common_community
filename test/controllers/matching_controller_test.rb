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
