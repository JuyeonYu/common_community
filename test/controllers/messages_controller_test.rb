require "test_helper"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @one = users(:one)
    @two = users(:two)
    @admin = users(:admin)
    @conv = conversations(:welcome_pair)
  end

  test "create: 비로그인 차단" do
    post conversation_messages_path(@conv), params: { message: { body: "hi" } }
    assert_redirected_to new_session_path
  end

  test "create: 비참가자 차단" do
    sign_in_as(@admin)
    post conversation_messages_path(@conv), params: { message: { body: "hi" } }
    assert_redirected_to conversations_path
  end

  test "create: 참가자 정상 발송" do
    sign_in_as(@one)
    assert_difference "Message.count", 1 do
      post conversation_messages_path(@conv), params: { message: { body: "안녕" } }
    end
    assert_redirected_to conversation_path(@conv)
  end

  test "create: body/이미지 둘 다 비면 422 (alert)" do
    sign_in_as(@one)
    assert_no_difference "Message.count" do
      post conversation_messages_path(@conv), params: { message: { body: "" } }
    end
  end

  test "create: 차단된 상대에게는 발송 불가" do
    # admin이 two를 차단한 픽스처. admin과 two 사이 conversation 생성 후 발송 시도
    sign_in_as(@admin)
    other_conv = Conversation.find_or_create_for(@admin, @two)

    assert_no_difference "Message.count" do
      post conversation_messages_path(other_conv), params: { message: { body: "hi" } }
    end
  end

  test "destroy: 본인 + 5분 이내 회수" do
    sign_in_as(@one)
    msg = @conv.messages.create!(sender: @one, body: "회수 테스트")

    assert_difference "Message.count", -1 do
      delete message_path(msg)
    end
    assert_redirected_to conversation_path(@conv)
  end

  test "destroy: 5분 지난 메시지 거부" do
    sign_in_as(@one)
    msg = @conv.messages.create!(sender: @one, body: "오래된 메시지")

    travel 6.minutes do
      assert_no_difference "Message.count" do
        delete message_path(msg)
      end
    end
  end

  test "destroy: 다른 사용자 거부" do
    sign_in_as(@two)
    msg = @conv.messages.create!(sender: @one, body: "다른 사용자 메시지")

    assert_no_difference "Message.count" do
      delete message_path(msg)
    end
  end

  # rate_limit은 Rails.cache에 의존하는데 test 환경은 :null_store라 카운트가 안 쌓임.
  # rate_limit 설정 자체는 messages_controller.rb에 명시돼 있고 dev/production cache_store에선 동작.
end
