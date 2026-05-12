require "test_helper"

class WebPushJobTest < ActiveJob::TestCase
  # Phase A: Notification 트리거가 비어 있어 알림 생성 자체가 불가.
  # Phase B/C에서 ACTIONS 채워지면 enqueue/페이로드 검증 테스트 복원.

  test "존재하지 않는 notification_id는 예외 없이 종료" do
    assert_nil WebPushJob.new.perform(0)
  end
end
