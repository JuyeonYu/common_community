require "test_helper"

class NotificationsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = users(:one) }

  test "index: 비로그인 차단" do
    get notifications_path
    assert_redirected_to new_session_path
  end

  test "index: 로그인 사용자는 빈 알림 페이지 조회" do
    sign_in_as(@user)
    get notifications_path

    assert_response :success
    assert_equal 0, Notification.unread.where(recipient: @user).count
  end

  test "read_all: 미읽 0 상태에서도 정상 리디렉트" do
    sign_in_as(@user)
    patch read_all_notifications_path

    assert_redirected_to notifications_path
  end
end
