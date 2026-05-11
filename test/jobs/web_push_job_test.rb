require "test_helper"

class WebPushJobTest < ActiveJob::TestCase
  setup do
    @recipient = users(:one)
    @actor     = users(:two)
    @post      = posts(:welcome)
    @notification = Notification.create!(
      recipient: @recipient, actor: @actor, action: "commented_on_post",
      notifiable: @post
    )
  end

  test "Notification 생성 시 WebPushJob enqueue" do
    assert_enqueued_jobs 1, only: WebPushJob do
      Notification.create!(
        recipient: @recipient, actor: @actor, action: "liked_post", notifiable: @post
      )
    end
  end

  test "VAPID 키 미설정(test 기본) 시 예외 없이 조용히 종료" do
    # test env에는 credentials.vapid가 없으므로 잡은 즉시 종료해야 한다.
    assert_nil WebPushJob.new.perform(@notification.id)
  end

  test "존재하지 않는 notification_id는 예외 없이 종료" do
    assert_nil WebPushJob.new.perform(0)
  end
end
