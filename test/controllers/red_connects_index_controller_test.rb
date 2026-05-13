require "test_helper"

class RedConnectsIndexControllerTest < ActionDispatch::IntegrationTest
  setup do
    @u1 = users(:one)
    @u2 = users(:two)
  end

  test "index: 비로그인 차단" do
    get red_connects_path
    assert_redirected_to new_session_path
  end

  test "index: 활성 RedConnect 없으면 빈 안내" do
    sign_in_as(@u1)
    get red_connects_path
    assert_response :success
    assert_match(/진행 중인 커넥트가 없습니다/, response.body)
  end

  test "index: 활성 RedConnect 노출" do
    rc = RedConnect.create!(user_a: @u1, user_b: @u2, expires_at: 1.month.from_now)
    sign_in_as(@u1)
    get red_connects_path
    assert_response :success
    assert_match(/#{@u2.name}/, response.body)
  end

  test "index: released 커넥트는 노출 X" do
    rc = RedConnect.create!(user_a: @u1, user_b: @u2, expires_at: 1.month.from_now)
    rc.update_columns(status: RedConnect.statuses[:released])
    sign_in_as(@u1)
    get red_connects_path
    assert_no_match(/#{@u2.name}/, response.body)
  end
end
