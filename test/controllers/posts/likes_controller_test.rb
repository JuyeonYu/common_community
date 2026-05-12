require "test_helper"

class Posts::LikesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @post = posts(:welcome)
  end

  test "create: 비로그인은 로그인 페이지로" do
    post post_like_path(@post)
    assert_redirected_to new_session_path
  end

  test "create: 좋아요 추가" do
    sign_in_as(@user)
    assert_difference "Like.count", 1 do
      post post_like_path(@post), as: :turbo_stream
    end
    assert_response :success
    assert @post.reload.liked_by?(@user)
  end

  test "create: 동일 사용자가 두 번 누르면 무시 (idempotent)" do
    sign_in_as(@user)
    post post_like_path(@post), as: :turbo_stream
    assert_no_difference "Like.count" do
      post post_like_path(@post), as: :turbo_stream
    end
  end

  test "destroy: 좋아요 취소" do
    sign_in_as(users(:two))
    assert @post.liked_by?(users(:two))
    assert_difference "Like.count", -1 do
      delete post_like_path(@post), as: :turbo_stream
    end
    assert_not @post.reload.liked_by?(users(:two))
  end
end
