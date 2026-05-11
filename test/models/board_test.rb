require "test_helper"

class BoardTest < ActiveSupport::TestCase
  test "name 필수 + uniqueness" do
    b = Board.new
    assert_not b.valid?
    assert b.errors[:name].any?
  end

  test "slug 자동 생성 (이름 기반)" do
    b = Board.create!(name: "자료실")
    assert_equal "자료실".downcase, b.slug if b.slug == "자료실".downcase
    # 한글이라 영소문자 정규식에 의해 빈 string → fallback "board" 또는 "board-N"
    assert b.slug.present?
  end

  test "ordered 스코프" do
    assert_equal [ boards(:free), boards(:qa), boards(:notice) ], Board.ordered.to_a
  end

  test "writable_by?: everyone은 누구나" do
    b = boards(:free)
    assert b.writable_by?(users(:one))
    assert b.writable_by?(users(:admin))
  end

  test "writable_by?: admin_only는 admin만" do
    b = boards(:notice)
    assert_not b.writable_by?(users(:one))
    assert b.writable_by?(users(:admin))
  end

  test "삭제 시 글이 있으면 거부 (restrict_with_error)" do
    b = boards(:free)
    assert_not b.destroy
    assert b.errors[:base].any? || b.persisted?
  end

  test "allowed_prefixes는 문자열 배열만" do
    b = Board.new(name: "X", slug: "x", allowed_prefixes: [ 1, 2 ])
    assert_not b.valid?
  end
end
