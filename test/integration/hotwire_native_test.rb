require "test_helper"

class HotwireNativeTest < ActionDispatch::IntegrationTest
  NATIVE_HEADERS = { "User-Agent" => "Turbo Native iOS" }.freeze

  test "기본 User-Agent에서는 웹 뷰가 렌더링됨" do
    get root_path
    assert_response :success
    assert_no_match(/data-native="true"/, response.body)
  end

  test "iOS Turbo Native UA에서 피드 native variant" do
    get root_path, headers: NATIVE_HEADERS
    assert_response :success
    assert_match(/data-native="true"/, response.body)
  end

  test "Android Turbo Native UA에서 피드 native variant" do
    get root_path, headers: { "User-Agent" => "Turbo Native Android" }
    assert_response :success
    assert_match(/data-native="true"/, response.body)
  end

  test "글 상세 native variant" do
    get post_path(posts(:welcome)), headers: NATIVE_HEADERS
    assert_response :success
    assert_match(/data-native="true"/, response.body)
  end

  test "글쓰기 native variant" do
    sign_in_as(users(:one))
    get new_post_path(board_slug: "free"), headers: NATIVE_HEADERS
    assert_response :success
    assert_match(/data-native="true"/, response.body)
  end

  test "프로필 native variant" do
    get profile_path(users(:one)), headers: NATIVE_HEADERS
    assert_response :success
    assert_match(/data-native="true"/, response.body)
  end

  test "로그인 native variant" do
    get new_session_path, headers: NATIVE_HEADERS
    assert_response :success
    assert_match(/data-native="true"/, response.body)
  end

  test "알림 native variant" do
    sign_in_as(users(:one))
    get notifications_path, headers: NATIVE_HEADERS
    assert_response :success
    assert_match(/data-native="true"/, response.body)
  end

  test "Path Configuration JSON 접근" do
    get "/configurations/ios_v1.json"
    assert_response :success
    assert_match(/application\/json/, response.media_type)
    body = JSON.parse(response.body)
    assert body["rules"].any? { |r| r.dig("properties", "context") == "modal" }, "modal 규칙 포함"
    assert body["rules"].any? { |r| r.dig("properties", "context") == "browser" }, "browser 규칙 포함"

    get "/configurations/android_v1.json"
    assert_response :success
  end
end
