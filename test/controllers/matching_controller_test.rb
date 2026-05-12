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
