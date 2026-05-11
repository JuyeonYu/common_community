require "test_helper"

class BoardsControllerTest < ActionDispatch::IntegrationTest
  test "index: 비로그인도 접근" do
    get boards_path
    assert_response :success
    assert_match(/자유/, response.body)
  end

  test "show: 게시판별 글 목록" do
    get board_path(boards(:free))
    assert_response :success
    assert_match(/환영합니다/, response.body)
  end

  test "show: 존재하지 않는 slug는 404" do
    get board_path("missing-slug")
    assert_response :not_found
  end
end
