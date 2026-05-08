require "test_helper"

class CommentTest < ActiveSupport::TestCase
  setup do
    @post = posts(:welcome)
    @user = users(:one)
    @top = comments(:top_on_welcome)
  end

  test "body 필수" do
    c = Comment.new(post: @post, user: @user, body: "")
    assert_not c.valid?
    assert c.errors[:body].any?
  end

  test "body 길이 제한 2000자" do
    c = Comment.new(post: @post, user: @user, body: "ㄱ" * 2001)
    assert_not c.valid?
  end

  test "top-level 댓글은 parent_id가 nil" do
    c = Comment.create!(post: @post, user: @user, body: "최상위")
    assert c.parent_id.nil?
    assert_not c.reply?
  end

  test "대댓글: parent가 top-level이면 OK" do
    reply = Comment.new(post: @post, user: @user, parent: @top, body: "답글")
    assert reply.valid?
  end

  test "대댓글의 대댓글은 거부 (2단계 제한)" do
    reply = Comment.create!(post: @post, user: @user, parent: @top, body: "1단계 답글")
    nested = Comment.new(post: @post, user: @user, parent: reply, body: "2단계 답글")
    assert_not nested.valid?
    assert nested.errors[:parent].any?
  end

  test "parent와 다른 post이면 거부" do
    other_post = posts(:second)
    c = Comment.new(post: other_post, user: @user, parent: @top, body: "잘못된 부모")
    assert_not c.valid?
    assert c.errors[:parent].any?
  end

  test "top_level 스코프는 답글 제외" do
    assert_includes Comment.top_level, comments(:top_on_welcome)
    assert_not_includes Comment.top_level, comments(:reply_on_welcome)
  end

  test "published 스코프는 hidden 제외" do
    assert_includes Comment.published, comments(:top_on_welcome)
    assert_not_includes Comment.published, comments(:hidden_comment)
  end

  test "post 삭제 시 댓글 cascade 삭제" do
    @post.comments.create!(user: @user, body: "삭제될 댓글")
    assert_difference "Comment.count", -@post.comments.count do
      @post.destroy
    end
  end

  test "top-level 삭제 시 답글 cascade 삭제" do
    initial_count = @top.replies.count + 1
    assert_difference "Comment.count", -initial_count do
      @top.destroy
    end
  end

  test "author?는 작성자만 true" do
    assert @top.author?(users(:two))
    assert_not @top.author?(users(:one))
    assert_not @top.author?(nil)
  end
end
