require "test_helper"

class ConversationTest < ActiveSupport::TestCase
  setup do
    @one = users(:one)
    @two = users(:two)
    @conv = conversations(:welcome_pair)
  end

  test "find_or_create_for: 자기 자신과는 거부" do
    assert_raises(ArgumentError) { Conversation.find_or_create_for(@one, @one) }
  end

  test "find_or_create_for: 두 사용자 사이는 1개만 (순서 무관)" do
    a = Conversation.find_or_create_for(@one, @two)
    b = Conversation.find_or_create_for(@two, @one)
    assert_equal a.id, b.id
  end

  test "find_or_create_for: user_one_id가 항상 더 작음" do
    a = users(:admin)
    b = users(:one)
    c = Conversation.find_or_create_for(a, b)
    assert c.user_one_id < c.user_two_id
  end

  test "participant?" do
    assert @conv.participant?(@one)
    assert @conv.participant?(@two)
    assert_not @conv.participant?(users(:admin))
    assert_not @conv.participant?(nil)
  end

  test "other_for: 상대방 반환" do
    assert_equal @two, @conv.other_for(@one)
    assert_equal @one, @conv.other_for(@two)
    assert_nil @conv.other_for(users(:admin))
  end

  test "unread_count_for: 본인이 보낸 것 제외 + last_read_at 기준" do
    # @one 입장: @two가 보낸 메시지 1개(second_msg, hidden_msg는 제외)
    assert_equal 1, @conv.unread_count_for(@one)

    # mark_read 후엔 0
    @conv.mark_read_for(@one)
    assert_equal 0, @conv.reload.unread_count_for(@one)
  end

  test "mark_read_for: 비참가자는 false" do
    assert_not @conv.mark_read_for(users(:admin))
  end
end
