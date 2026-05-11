require "test_helper"

class BlockTest < ActiveSupport::TestCase
  setup do
    @admin = users(:admin)
    @one = users(:one)
    @two = users(:two)
  end

  test "자기 자신 차단 거부" do
    b = Block.new(blocker: @one, blocked: @one)
    assert_not b.valid?
    assert b.errors[:base].any?
  end

  test "동일 (blocker, blocked) 쌍은 unique" do
    Block.create!(blocker: @one, blocked: @two)
    dup = Block.new(blocker: @one, blocked: @two)
    assert_not dup.valid?
  end

  test "exists_between?: 양방향 모두 true (픽스처: admin이 two 차단)" do
    assert Block.exists_between?(@admin, @two)
    assert Block.exists_between?(@two, @admin)
  end

  test "exists_between?: 무관한 사용자 쌍은 false" do
    assert_not Block.exists_between?(@one, @two)
  end

  test "exists_between?: nil 입력은 false" do
    assert_not Block.exists_between?(nil, @two)
    assert_not Block.exists_between?(@two, nil)
  end

  test "user 삭제 시 blocks cascade (made + received)" do
    fresh = User.create!(email_address: "fresh@example.com", name: "임시", password: "password")
    Block.create!(blocker: fresh, blocked: @one)
    Block.create!(blocker: @two, blocked: fresh)

    assert_difference "Block.count", -2 do
      fresh.destroy
    end
  end
end
