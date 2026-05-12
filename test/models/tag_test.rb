require "test_helper"

class TagTest < ActiveSupport::TestCase
  test "name 필수 + 유일" do
    Tag.create!(name: "uniq-tag")
    dup = Tag.new(name: "uniq-tag")
    assert_not dup.valid?
  end

  test "slug 자동 생성 (영문은 소문자+대시)" do
    tag = Tag.create!(name: "Rails 8")
    assert_equal "rails-8", tag.slug
  end

  test "slug 자동 생성 (한글은 그대로)" do
    tag = Tag.create!(name: "한글태그")
    assert_equal "한글태그", tag.slug
  end

  test "from_names: 콤마/공백/중복/빈값 처리" do
    tags = Tag.from_names(" rails, hotwire,, rails ")
    assert_equal [ "hotwire", "rails" ], tags.map(&:name).sort
  end

  test "to_param은 slug 반환" do
    tag = Tag.create!(name: "test-tag")
    assert_equal "test-tag", tag.to_param
  end
end
