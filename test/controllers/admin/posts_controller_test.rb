require "test_helper"

class Admin::PostsControllerTest < ActionDispatch::IntegrationTest
  setup { @post = posts(:welcome) }

  test "index: admin 접근" do
    sign_in_as(users(:admin))
    get admin_posts_path
    assert_response :success
    assert_match(/환영합니다/, response.body)
  end

  test "index: 비admin 차단" do
    sign_in_as(users(:one))
    get admin_posts_path
    assert_redirected_to root_path
  end

  test "hide: 게시물 숨김" do
    sign_in_as(users(:admin))
    post hide_admin_post_path(@post)
    assert @post.reload.hidden?
  end

  test "unhide: 숨김 해제" do
    @post.update!(status: :hidden)
    sign_in_as(users(:admin))
    post unhide_admin_post_path(@post)
    assert @post.reload.published?
  end

  test "destroy: admin 삭제" do
    sign_in_as(users(:admin))
    assert_difference "Post.count", -1 do
      delete admin_post_path(@post)
    end
  end
end
