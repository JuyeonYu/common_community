require "test_helper"

class ConnectRequestTest < ActiveSupport::TestCase
  setup do
    @male   = users(:one).tap { |u| u.update!(gender: :male) }
    @female = users(:two).tap { |u| u.update!(gender: :female) }
    @other_female = users(:admin).tap { |u| u.update!(gender: :female) }
  end

  test "create: gen_week 자동 부여 + pending" do
    req = ConnectRequest.create!(requester: @male, target: @female)
    assert_equal ConnectRequest.current_gen_week, req.gen_week
    assert req.pending?
  end

  test "본인에게 요청 불가" do
    req = ConnectRequest.new(requester: @male, target: @male)
    assert_not req.valid?
  end

  test "같은 기수 두 번 요청 불가 (1기수 1명)" do
    ConnectRequest.create!(requester: @male, target: @female)
    second = ConnectRequest.new(requester: @male, target: @other_female)
    assert_not second.valid?
  end

  test "accept!: RedConnect 생성 + 다른 pending 자동 취소" do
    a = ConnectRequest.create!(requester: @male, target: @female)
    # @female이 받은 다른 pending 요청 — admin도 male이 아니라 female이라 setup 위배. 다시.
    yet_male = users(:inactive).tap { |u| u.update!(gender: :male, seed: true, invitation_accepted_at: Time.current) }
    b = ConnectRequest.create!(requester: yet_male, target: @female)

    assert_difference "RedConnect.count", 1 do
      a.accept!
    end
    assert a.reload.accepted?
    assert b.reload.cancelled?
  end

  test "accept!: 알림 발송 (요청자에게)" do
    a = ConnectRequest.create!(requester: @male, target: @female)
    assert_difference "Notification.where(action: 'connect_accepted').count", 1 do
      a.accept!
    end
  end

  test "create 시 target에게 connect_requested 알림 발송" do
    assert_difference "Notification.where(action: 'connect_requested', recipient_id: @female.id).count", 1 do
      ConnectRequest.create!(requester: @male, target: @female)
    end
  end
end
