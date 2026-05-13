require "test_helper"

class Matching::CandidatesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @male = users(:one).tap { |u|
      u.update!(gender: :male, nickname: "남자1", birth_date: 30.years.ago.to_date,
                residence_area: :seoul, job_title: "개발", smoking: :non_smoker,
                hobby: "러닝", bio: "안녕")
      u.avatar.attach(io: StringIO.new("a"), filename: "a.png", content_type: "image/png")
      u.enable_matching!
    }
    @female = users(:two).tap { |u|
      u.update!(gender: :female, nickname: "여자2", birth_date: 28.years.ago.to_date,
                residence_area: :seoul, job_title: "기획", smoking: :non_smoker,
                hobby: "사진", bio: "안녕")
      u.avatar.attach(io: StringIO.new("b"), filename: "b.png", content_type: "image/png")
      u.enable_matching!
    }
  end

  test "비활성 사용자 차단" do
    @male.disable_matching!
    sign_in_as(@male)
    get matching_candidate_path(@female)
    assert_redirected_to matching_path
  end

  test "활성 사용자 매칭 풀에 없는 사용자 차단" do
    sign_in_as(@male)
    get matching_candidate_path(users(:admin)) # admin은 매칭 풀 X
    assert_redirected_to matching_path
  end

  test "활성 사용자 풀 후보 조회 가능 + 풀 프로필 노출" do
    sign_in_as(@male)
    get matching_candidate_path(@female)
    assert_response :success
    assert_match(/여자2/, response.body)
    assert_match(/기획/, response.body)
    assert_match(/안녕/, response.body)
  end

  test "노출 시 MatchExposure 생성" do
    sign_in_as(@male)
    assert_difference -> { MatchExposure.where(viewer: @male, target: @female).count }, 1 do
      get matching_candidate_path(@female)
    end
  end
end
