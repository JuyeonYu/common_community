require "test_helper"

class ChatMessageTest < ActiveSupport::TestCase
  setup do
    @u1 = users(:one)
    @u2 = users(:two)
    @rc = RedConnect.create!(user_a: @u1, user_b: @u2, expires_at: 1.month.from_now)
  end

  test "유효한 메시지" do
    m = ChatMessage.new(red_connect: @rc, sender: @u1, body: "안녕하세요")
    assert m.valid?
  end

  test "본문 비어있으면 invalid" do
    m = ChatMessage.new(red_connect: @rc, sender: @u1, body: "")
    assert_not m.valid?
  end

  test "본문 이미지 URL 차단" do
    m = ChatMessage.new(red_connect: @rc, sender: @u1, body: "사진 https://x.com/a.jpg 봐")
    assert_not m.valid?
    assert_includes m.errors[:body].first, "이미지 URL"
  end

  test "구성원이 아닌 사용자는 invalid" do
    outsider = users(:admin)
    m = ChatMessage.new(red_connect: @rc, sender: outsider, body: "남이다")
    assert_not m.valid?
  end

  test "종료된 커넥트는 invalid" do
    @rc.release!(reason: "test")
    m = ChatMessage.new(red_connect: @rc, sender: @u1, body: "끝났는데?")
    assert_not m.valid?
  end

  test "create 시 상대에게 chat_message 알림" do
    assert_difference "Notification.where(action: 'chat_message', recipient_id: @u2.id).count", 1 do
      ChatMessage.create!(red_connect: @rc, sender: @u1, body: "hi")
    end
  end

  test "recipient = 상대 사용자" do
    m = ChatMessage.create!(red_connect: @rc, sender: @u1, body: "안녕")
    assert_equal @u2, m.recipient
  end
end
