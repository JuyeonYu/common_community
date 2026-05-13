require "test_helper"

class LikeTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @post = posts(:welcome)
    @comment = comments(:top_on_welcome)
  end

  test "사용자는 같은 likeable에 한 번만 좋아요 가능" do
    Like.create!(user: @user, likeable: @post)
    dup = Like.new(user: @user, likeable: @post)
    assert_not dup.valid?
    assert dup.errors[:user_id].any?
  end

  test "다른 사용자는 같은 likeable에 좋아요 가능" do
    # 픽스처: users(:two)가 이미 @post 좋아요. user_one도 좋아요 추가.
    Like.create!(user: @user, likeable: @post)
    assert_equal 2, @post.likes.count
  end

  test "같은 사용자가 다른 likeable에 좋아요 가능" do
    Like.create!(user: @user, likeable: @post)
    # 픽스처: user_one이 이미 @comment 좋아요 → 위에 추가하면 user_one은 총 2개
    assert_equal 2, @user.likes.count
  end

  test "Likeable concern: liked_by? / likes_count" do
    assert @post.liked_by?(users(:two))
    assert_not @post.liked_by?(users(:one))
    assert_not @post.liked_by?(nil)
    assert_equal 1, @post.likes_count
  end

  test "post 삭제 시 likes cascade" do
    fresh = Post.create!(user: @user, title: "임시", body: "<p>x</p>")
    Like.create!(user: users(:two), likeable: fresh)

    assert_difference "Like.count", -1 do
      fresh.destroy
    end
  end

  test "user 삭제 시 likes cascade" do
    fresh_user = User.create!(email_address: "fresh@example.com", name: "임시")
    Like.create!(user: fresh_user, likeable: @post)

    assert_difference "Like.count", -1 do
      fresh_user.destroy
    end
  end
end
