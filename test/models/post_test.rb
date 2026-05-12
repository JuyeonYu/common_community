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
end
