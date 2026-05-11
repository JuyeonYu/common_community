require "test_helper"

class ConversationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @one = users(:one)
    @two = users(:two)
    @admin = users(:admin)
    @conv = conversations(:welcome_pair)
  end

  test "index: 비로그인 차단" do
    get conversations_path
    assert_redirected_to new_session_path
  end

  test "index: 본인 대화방 목록" do
    sign_in_as(@one)
    get conversations_path
    assert_response :success
  end

  test "show: 비참가자 차단" do
    sign_in_as(@admin)
    get conversation_path(@conv)
    assert_redirected_to conversations_path
    assert_match(/권한/, flash[:alert])
  end

  test "show: 참가자 진입 + 자동 읽음 처리" do
    sign_in_as(@one)
    get conversation_path(@conv)
    assert_response :success
    assert_not_nil @conv.reload.last_read_at_for(@one)
  end

  test "create: 신규 대화 시작" do
    sign_in_as(@admin)
    assert_difference "Conversation.count", 1 do
      post conversations_path, params: { with_user_id: @one.id }
    end
  end

  test "create: 기존 대화 재사용" do
    sign_in_as(@one)
    assert_no_difference "Conversation.count" do
      post conversations_path, params: { with_user_id: @two.id }
    end
    assert_redirected_to @conv
  end

  test "create: 자기 자신 거부" do
    sign_in_as(@one)
    assert_no_difference "Conversation.count" do
      post conversations_path, params: { with_user_id: @one.id }
    end
    assert_redirected_to conversations_path
  end

  test "create: 차단된 사용자 거부 (admin이 two 차단 픽스처)" do
    sign_in_as(@admin)
    assert_no_difference "Conversation.count" do
      post conversations_path, params: { with_user_id: @two.id }
    end
  end

  test "read: 비로그인 차단" do
    patch read_conversation_path(@conv)
    assert_redirected_to new_session_path
  end

  test "read: 비참가자는 403 (json)" do
    sign_in_as(@admin)
    patch read_conversation_path(@conv), as: :json
    assert_response :forbidden
  end

  test "read: 참가자가 호출하면 last_read_at 갱신 + 204" do
    sign_in_as(@one)
    @conv.update_columns(user_one_last_read_at: nil, user_two_last_read_at: nil)

    patch read_conversation_path(@conv), as: :json

    assert_response :no_content
    assert_not_nil @conv.reload.last_read_at_for(@one)
  end
end
