require "test_helper"

class RedConnectTest < ActiveSupport::TestCase
  setup do
    @u1 = users(:one)
    @u2 = users(:two)
  end

  test "create: user_a/user_b 정렬(작은 id가 user_a)" do
    rc = RedConnect.create!(user_a: @u2, user_b: @u1, expires_at: 1.month.from_now)
    assert_equal [ @u1.id, @u2.id ].sort, [ rc.user_a_id, rc.user_b_id ]
  end

  test "between scope: 순서 무관 매칭" do
    RedConnect.create!(user_a: @u1, user_b: @u2, expires_at: 1.month.from_now)
    assert RedConnect.between(@u2, @u1).exists?
    assert RedConnect.between(@u1, @u2).exists?
  end

  test "동일 페어 unique" do
    RedConnect.create!(user_a: @u1, user_b: @u2, expires_at: 1.month.from_now)
    assert_raises(ActiveRecord::RecordNotUnique) do
      RedConnect.create!(user_a: @u1, user_b: @u2, expires_at: 1.month.from_now)
    end
  end

  test "other_user" do
    rc = RedConnect.create!(user_a: @u1, user_b: @u2, expires_at: 1.month.from_now)
    assert_equal @u2, rc.other_user(@u1)
    assert_equal @u1, rc.other_user(@u2)
  end

  test "release! / expire!" do
    rc = RedConnect.create!(user_a: @u1, user_b: @u2, expires_at: 1.month.from_now)
    rc.release!(reason: "manual")
    assert rc.reload.released?
    assert_equal "manual", rc.release_reason
  end
end
