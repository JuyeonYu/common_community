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
end
