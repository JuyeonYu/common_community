require "test_helper"

class BlocksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @one = users(:one)
    @two = users(:two)
    @admin = users(:admin)
  end

  test "index: 비로그인 차단" do
    get blocks_path
    assert_redirected_to new_session_path
  end

  test "index: 본인 차단 목록" do
    sign_in_as(@admin)
    get blocks_path
    assert_response :success
  end

  test "create: 차단 추가" do
    sign_in_as(@one)
    assert_difference "Block.count", 1 do
      post blocks_path, params: { blocked_id: @two.id }
    end
  end

  test "create: 자기 자신 차단 거부" do
    sign_in_as(@one)
    assert_no_difference "Block.count" do
      post blocks_path, params: { blocked_id: @one.id }
    end
  end

  test "create: 중복 차단은 idempotent (no error)" do
    sign_in_as(@admin)
    assert_no_difference "Block.count" do
      post blocks_path, params: { blocked_id: @two.id }
    end
  end

  test "destroy: 차단 해제" do
    sign_in_as(@admin)
    block = blocks(:admin_blocks_two)

    assert_difference "Block.count", -1 do
      delete block_path(block)
    end
    assert_redirected_to blocks_path
  end

  test "destroy: 다른 사용자의 block은 못 지움" do
    sign_in_as(@one)
    block = blocks(:admin_blocks_two)

    delete block_path(block)
    assert_response :not_found
    assert Block.exists?(block.id)
  end
end
