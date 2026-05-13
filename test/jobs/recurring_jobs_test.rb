require "test_helper"

class RecurringJobsTest < ActiveJob::TestCase
  test "InvitationExpireJob: 만료 시각 지난 pending → expired" do
    inv = users(:one).sent_invitations.create!(
      recommendation_comment: "테스트 추천서",
      invitee_email: "expire-test@example.com",
      expires_at: 1.hour.ago
    )
    assert inv.pending?
    InvitationExpireJob.new.perform
    assert inv.reload.expired?
  end

  test "RedConnectExpireJob: 만료 active → expired" do
    rc = RedConnect.create!(user_a: users(:one), user_b: users(:two), expires_at: 1.minute.ago)
    rc.update_columns(status: RedConnect.statuses[:active]) # 강제로 active 유지
    RedConnectExpireJob.new.perform
    assert rc.reload.expired?
  end

  test "ConnectRequestExpireJob: 이전 기수 pending → expired" do
    u1 = users(:one).tap { |u| u.update!(gender: :male) }
    u2 = users(:two).tap { |u| u.update!(gender: :female) }
    req = ConnectRequest.create!(requester: u1, target: u2)
    req.update_columns(gen_week: "2020W01") # 이전 기수로 강제
    ConnectRequestExpireJob.new.perform
    assert req.reload.expired?
  end
end
