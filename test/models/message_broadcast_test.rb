require "test_helper"

class MessageBroadcastTest < ActiveSupport::TestCase
  setup do
    @one = users(:one)
    @two = users(:two)
    @conv = conversations(:welcome_pair)
  end

  test "Message 생성 시 broadcast 콜백이 partial 렌더링 정상 (예외 없음)" do
    assert_nothing_raised do
      @conv.messages.create!(sender: @one, body: "broadcast test")
    end
  end

  test "Message 삭제 시 broadcast_remove + 뱃지 갱신 (예외 없음)" do
    msg = @conv.messages.create!(sender: @one, body: "to be removed")
    assert_nothing_raised { msg.destroy }
  end

  test "User#broadcast_messages_badge 호출 가능" do
    assert_nothing_raised { @one.broadcast_messages_badge }
  end

  test "Message#recipient는 발송자의 상대방" do
    msg = @conv.messages.create!(sender: @one, body: "x")
    assert_equal @two, msg.recipient
  end
end
