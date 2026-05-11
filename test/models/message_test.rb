require "test_helper"

class MessageTest < ActiveSupport::TestCase
  setup do
    @one = users(:one)
    @two = users(:two)
    @conv = conversations(:welcome_pair)
  end

  test "body 또는 images 중 하나는 필수" do
    msg = Message.new(conversation: @conv, sender: @one)
    assert_not msg.valid?
    assert msg.errors[:base].any?
  end

  test "body만 있어도 valid" do
    msg = Message.new(conversation: @conv, sender: @one, body: "내용")
    assert msg.valid?
  end

  test "body 길이 2000자 제한" do
    msg = Message.new(conversation: @conv, sender: @one, body: "ㄱ" * 2001)
    assert_not msg.valid?
  end

  test "비참가자 sender는 거부" do
    msg = Message.new(conversation: @conv, sender: users(:admin), body: "내용")
    assert_not msg.valid?
    assert msg.errors[:sender].any?
  end

  test "기본 status는 visible" do
    msg = Message.create!(conversation: @conv, sender: @one, body: "x")
    assert msg.status_visible?
  end

  test "recallable_by?: 발송자 + 5분 이내" do
    msg = Message.create!(conversation: @conv, sender: @one, body: "x")
    assert msg.recallable_by?(@one)
    assert_not msg.recallable_by?(@two)
    assert_not msg.recallable_by?(nil)

    travel 6.minutes do
      assert_not msg.recallable_by?(@one)
    end
  end

  test "recipient: 발송자의 상대방" do
    msg = Message.create!(conversation: @conv, sender: @one, body: "x")
    assert_equal @two, msg.recipient
  end

  test "Reportable include 동작" do
    msg = messages(:first_msg)
    assert_respond_to msg, :reports
    assert_respond_to msg, :reported_by?
  end

  test "after_create_commit이 conversation.last_message_at 갱신" do
    travel_to Time.current do
      msg = Message.create!(conversation: @conv, sender: @one, body: "ping")
      assert_in_delta Time.current.to_f, @conv.reload.last_message_at.to_f, 1.0
    end
  end

  test "conversation 삭제 시 messages cascade" do
    fresh = Conversation.find_or_create_for(@one, users(:admin))
    fresh.messages.create!(sender: @one, body: "x")
    assert_difference "Message.count", -1 do
      fresh.destroy
    end
  end
end
