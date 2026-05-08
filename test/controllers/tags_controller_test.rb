require "test_helper"

class TagsControllerTest < ActionDispatch::IntegrationTest
  test "show: 태그별 글 목록" do
    get tag_path(tags(:rails))
    assert_response :success
    assert_match(/rails/, response.body)
    assert_match(/환영합니다/, response.body)
  end

  test "show: 존재하지 않는 슬러그는 404" do
    get tag_path("missing-slug")
    assert_response :not_found
  end

  test "show: 태그에 hidden 글은 노출 안 됨" do
    posts(:welcome).update!(status: :hidden)
    get tag_path(tags(:rails))
    assert_no_match(/환영합니다/, response.body)
  end
end
