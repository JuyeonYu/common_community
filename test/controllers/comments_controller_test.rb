require "test_helper"

class CommentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @post = posts(:welcome)
    @user = users(:one)
    @other = users(:two)
    @top = comments(:top_on_welcome)
    @reply = comments(:reply_on_welcome)
  end

  test "create: 비로그인은 로그인 페이지로" do
    post post_comments_path(@post), params: { comment: { body: "익명 댓글" } }
    assert_redirected_to new_session_path
  end

  test "create: top-level 댓글 작성" do
    sign_in_as(@user)
    assert_difference "Comment.count", 1 do
      post post_comments_path(@post), params: { comment: { body: "새 댓글" } },
        as: :turbo_stream
    end
    assert_response :success
  end

  test "create: 대댓글 작성" do
    sign_in_as(@user)
    assert_difference "Comment.count", 1 do
      post post_comments_path(@post),
        params: { comment: { body: "답글", parent_id: @top.id } },
        as: :turbo_stream
    end
    created = Comment.order(:created_at).last
    assert_equal @top.id, created.parent_id
  end

  test "create: 답글에 답글은 거부" do
    sign_in_as(@user)
    assert_no_difference "Comment.count" do
      post post_comments_path(@post),
        params: { comment: { body: "잘못된 답글", parent_id: @reply.id } }
    end
    assert_redirected_to @post
  end

  test "destroy: 본인 댓글 삭제" do
    sign_in_as(@other)
    assert_difference "Comment.count", -1 - @top.replies.count do
      delete comment_path(@top), as: :turbo_stream
    end
  end

  test "destroy: 다른 사용자는 차단" do
    sign_in_as(@user)
    assert_no_difference "Comment.count" do
      delete comment_path(@top)
    end
    assert_redirected_to @post
    assert_match(/권한/, flash[:alert])
  end

  test "destroy: admin은 다른 사람 댓글도 삭제 가능" do
    sign_in_as(users(:admin))
    assert_difference "Comment.count", -1 - @top.replies.count do
      delete comment_path(@top), as: :turbo_stream
    end
  end

  test "edit/update: 본인만 가능" do
    sign_in_as(@user)
    get edit_comment_path(@top)
    assert_redirected_to @post
  end

  test "update: 본인 댓글 수정" do
    sign_in_as(@other)
    patch comment_path(@top), params: { comment: { body: "수정된 내용" } }
    assert_redirected_to @post
    assert_equal "수정된 내용", @top.reload.body
  end
end
