require "test_helper"

class PostTest < ActiveSupport::TestCase
  setup { @user = users(:one) }

  test "title 필수" do
    post = Post.new(user: @user, body: "<p>본문</p>")
    assert_not post.valid?
    assert post.errors[:title].any?
  end

  test "body 필수" do
    post = Post.new(user: @user, title: "제목")
    assert_not post.valid?
    assert post.errors[:body].any?
  end

  test "published 스코프는 hidden을 제외" do
    assert_includes Post.published, posts(:welcome)
    assert_not_includes Post.published, posts(:hidden)
  end

  test "tag_names= 콤마 구분 문자열로 태그 연결" do
    post = Post.new(user: @user, title: "테스트", body: "<p>본문</p>")
    post.tag_names = "rails, 새태그, ,rails"
    assert post.save
    assert_equal [ "rails", "새태그" ].sort, post.tags.map(&:name).sort
  end

  test "author?는 작성자만 true" do
    post = posts(:welcome)
    assert post.author?(users(:one))
    assert_not post.author?(users(:two))
    assert_not post.author?(nil)
  end

  test "search_by_text: 제목 매칭" do
    results = Post.search_by_text("환영")
    assert_includes results, posts(:welcome)
  end

  test "search_by_text: 본문 매칭 (Action Text body 조인)" do
    results = Post.search_by_text("안녕하세요")
    assert_includes results, posts(:welcome)
  end

  test "search_by_text + for_feed: hidden 글은 제외" do
    results = Post.for_feed.search_by_text("가려진")
    assert_not_includes results, posts(:hidden)
  end

  test "search_by_text: 빈 문자열은 결과 없음" do
    assert_empty Post.search_by_text("")
  end

  # --- 멘션 (Phase E-3) ---

  test "본문 @닉네임이 매칭되면 해당 사용자에게 mentioned 알림" do
    target = users(:two)
    assert_difference -> { Notification.where(action: "mentioned").count }, 1 do
      Post.create!(user: @user, title: "멘션", body: "<p>안녕 @#{target.nickname}</p>")
    end
    assert_equal target, Notification.where(action: "mentioned").last.recipient
  end

  test "자기 자신 멘션은 알림 없음" do
    assert_no_difference -> { Notification.where(action: "mentioned").count } do
      Post.create!(user: @user, title: "셀프", body: "<p>나 @#{@user.nickname}</p>")
    end
  end

  test "존재하지 않는 닉네임은 무시" do
    assert_no_difference -> { Notification.where(action: "mentioned").count } do
      Post.create!(user: @user, title: "없는닉", body: "<p>@없는닉네임_123</p>")
    end
  end
end
