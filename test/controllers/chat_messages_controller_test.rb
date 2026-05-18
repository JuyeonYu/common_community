require "test_helper"

class ChatMessagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @u1 = users(:one)
    @u2 = users(:two)
    @rc = RedConnect.create!(user_a: @u1, user_b: @u2, expires_at: 1.month.from_now)
  end

  test "create: 참여자가 메시지 전송" do
    sign_in_as(@u1)
    assert_difference "ChatMessage.count", 1 do
      post red_connect_chat_messages_path(@rc), params: { chat_message: { body: "안녕!" } }, as: :turbo_stream
    end
    assert_response :success
  end

  test "create: 비참여자는 404" do
    sign_in_as(users(:admin))
    post red_connect_chat_messages_path(@rc), params: { chat_message: { body: "남이다" } }
    assert_response :not_found
  end

  test "create: 본문 이미지 URL 차단" do
    sign_in_as(@u1)
    assert_no_difference "ChatMessage.count" do
      post red_connect_chat_messages_path(@rc), params: { chat_message: { body: "https://x.com/a.png" } }
    end
  end

  # --- 읽음 확인 (Phase F-2-c) ---

  test "mark_read: 발신자가 결제 → read_check_paid + 크레딧 차감" do
    msg = @rc.chat_messages.create!(sender: @u1, body: "안녕")
    cost = Rails.application.config.x.blackticket.chat_read_receipt_cost
    @u1.credit_transactions.create!(amount: cost * 2, kind: :admin_grant, memo: "seed")
    sign_in_as(@u1)
    before = @u1.reload.ticket_credits

    post mark_read_red_connect_chat_message_path(@rc, msg)
    assert msg.reload.read_check_paid?
    assert_equal before - cost, @u1.reload.ticket_credits
  end

  test "mark_read: 본인 메시지가 아니면 거절" do
    msg = @rc.chat_messages.create!(sender: @u2, body: "남의것")
    sign_in_as(@u1)
    post mark_read_red_connect_chat_message_path(@rc, msg)
    assert_not msg.reload.read_check_paid?
    assert_match(/본인이 보낸/, flash[:alert])
  end

  test "mark_read: 이미 결제된 메시지 안내" do
    msg = @rc.chat_messages.create!(sender: @u1, body: "이미", read_check_paid: true)
    sign_in_as(@u1)
    post mark_read_red_connect_chat_message_path(@rc, msg)
    assert_match(/이미 결제/, flash[:notice])
  end

  test "mark_read: 잔액 부족 거절" do
    msg = @rc.chat_messages.create!(sender: @u1, body: "잔액부족")
    sign_in_as(@u1)
    post mark_read_red_connect_chat_message_path(@rc, msg)
    assert_match(/크레딧이 부족/, flash[:alert])
  end

  test "show: 수신자가 채팅방 진입 시 받은 메시지 read_at 자동 세팅" do
    msg = @rc.chat_messages.create!(sender: @u1, body: "수신자 읽기 전")
    assert_nil msg.read_at
    sign_in_as(@u2)
    get red_connect_path(@rc)
    assert_not_nil msg.reload.read_at
  end
end
