require "test_helper"

class PostTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @board = boards(:free)
  end

  test "title 필수" do
    post = Post.new(user: @user, board: @board, body: "<p>본문</p>")
    assert_not post.valid?
    assert post.errors[:title].any?
  end

  test "body 필수" do
    post = Post.new(user: @user, board: @board, title: "제목")
    assert_not post.valid?
    assert post.errors[:body].any?
  end

  test "board 필수" do
    post = Post.new(user: @user, title: "제목", body: "<p>x</p>")
    assert_not post.valid?
    assert post.errors[:board].any?
  end

  test "prefix는 board.allowed_prefixes에 있어야 valid" do
    qa = boards(:qa) # allowed: [초보, 고급]
    ok = Post.new(user: @user, board: qa, title: "x", body: "<p>x</p>", prefix: "초보")
    bad = Post.new(user: @user, board: qa, title: "x", body: "<p>x</p>", prefix: "잘못된말머리")
    assert ok.valid?
    assert_not bad.valid?
    assert bad.errors[:prefix].any?
  end

  test "prefix 없으면 valid (선택사항)" do
    post = Post.new(user: @user, board: @board, title: "x", body: "<p>x</p>")
    assert post.valid?
  end

  test "published 스코프는 hidden을 제외" do
    assert_includes Post.published, posts(:welcome)
    assert_not_includes Post.published, posts(:hidden)
  end

  test "tag_names= 콤마 구분 문자열로 태그 연결" do
    post = Post.new(user: @user, board: @board, title: "테스트", body: "<p>본문</p>")
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

  test "search_by_text: 한글 prefix" do
    results = Post.search_by_text("두 번째")
    assert_includes results, posts(:second)
  end

  test "search_by_text + for_feed: hidden 글은 제외" do
    results = Post.for_feed.search_by_text("가려진")
    assert_not_includes results, posts(:hidden)
  end

  test "search_by_text: 빈 문자열은 결과 없음" do
    assert_empty Post.search_by_text("")
  end
end
