require "test_helper"

class RedConnectsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @u1 = users(:one)
    @u2 = users(:two)
    @rc = RedConnect.create!(user_a: @u1, user_b: @u2, expires_at: 1.month.from_now)
  end

  test "show: 비참여자는 404" do
    sign_in_as(users(:admin))
    get red_connect_path(@rc)
    assert_response :not_found
  end

  test "show: 참여자 조회" do
    sign_in_as(@u1)
    get red_connect_path(@rc)
    assert_response :success
  end

  test "destroy: 참여자 해제 + 상대 알림" do
    sign_in_as(@u1)
    assert_difference "Notification.where(action: 'connect_released', recipient_id: @u2.id).count", 1 do
      delete red_connect_path(@rc)
    end
    assert @rc.reload.released?
    assert_redirected_to red_connects_path
  end
end
