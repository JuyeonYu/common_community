require "test_helper"

class ScoreEventTest < ActiveSupport::TestCase
  setup { @user = users(:one) }

  test "apply_to_user: delta 만큼 누적" do
    before = @user.ticket_score
    @user.score_events.create!(delta: -2, reason: :admin_adjust, memo: "test")
    assert_equal before - 2, @user.reload.ticket_score
  end

  test "스코어 0 도달 시 자동 정지" do
    @user.score_events.create!(delta: -10, reason: :admin_adjust, memo: "drain")
    @user.reload
    assert @user.ticket_score <= 0
    assert @user.suspended?
  end

  test "이미 정지 상태면 재정지 X" do
    @user.suspend!
    original = @user.suspended_until
    @user.score_events.create!(delta: -100, reason: :admin_adjust, memo: "more")
    assert_equal original.to_i, @user.reload.suspended_until.to_i
  end
end
