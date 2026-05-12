require "test_helper"

class Comments::LikesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:two)
    @comment = comments(:top_on_welcome)
  end

  test "create: 비로그인은 로그인 페이지로" do
    post comment_like_path(@comment)
    assert_redirected_to new_session_path
  end

  test "create: 댓글 좋아요 추가" do
    sign_in_as(@user)
    assert_difference "Like.count", 1 do
      post comment_like_path(@comment), as: :turbo_stream
    end
    assert @comment.reload.liked_by?(@user)
  end

  test "destroy: 댓글 좋아요 취소" do
    sign_in_as(users(:one))
    assert @comment.liked_by?(users(:one))
    assert_difference "Like.count", -1 do
      delete comment_like_path(@comment), as: :turbo_stream
    end
  end
end
