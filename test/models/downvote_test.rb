require "test_helper"

class DownvoteTest < ActiveSupport::TestCase
  setup do
    @u1 = users(:one)
    @u2 = users(:two)
    @rc = RedConnect.create!(user_a: @u1, user_b: @u2, expires_at: 1.month.from_now)
  end

  test "false_info: RedConnect 자동 해제 + 스코어 -1 + 알림" do
    before_score = @u2.ticket_score
    penalty = Rails.application.config.x.blackticket.downvote_penalty

    assert_difference -> { Notification.where(action: "downvoted", recipient_id: @u2.id).count }, 1 do
      Downvote.create!(from_user: @u1, to_user: @u2, red_connect: @rc, kind: :false_info)
    end

    assert @rc.reload.released?
    assert_equal before_score + penalty, @u2.reload.ticket_score
  end

  test "abusive: 동일하게 페널티" do
    before_score = @u2.ticket_score
    Downvote.create!(from_user: @u1, to_user: @u2, red_connect: @rc, kind: :abusive)
    assert_equal before_score + Rails.application.config.x.blackticket.downvote_penalty, @u2.reload.ticket_score
  end

  test "incompatible: 페널티 없음, 해제만" do
    before_score = @u2.ticket_score
    Downvote.create!(from_user: @u1, to_user: @u2, red_connect: @rc, kind: :incompatible)
    assert @rc.reload.released?
    assert_equal before_score, @u2.reload.ticket_score
  end

  test "구성원 아닌 사용자는 invalid" do
    outsider = users(:admin)
    dv = Downvote.new(from_user: outsider, to_user: @u2, red_connect: @rc, kind: :false_info)
    assert_not dv.valid?
  end

  test "본인을 비추천 불가" do
    dv = Downvote.new(from_user: @u1, to_user: @u1, red_connect: @rc, kind: :false_info)
    assert_not dv.valid?
  end

  test "동일 커넥트에서 동일 사용자가 두 번 비추천 불가" do
    Downvote.create!(from_user: @u1, to_user: @u2, red_connect: @rc, kind: :false_info)
    dup = Downvote.new(from_user: @u1, to_user: @u2, red_connect: @rc, kind: :abusive)
    assert_raises(ActiveRecord::RecordNotUnique) do
      dup.save(validate: false)
    end
  end
end
