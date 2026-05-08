require "test_helper"

class NotificationsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = users(:one) }

  test "index: 비로그인 차단" do
    get notifications_path
    assert_redirected_to new_session_path
  end

  test "index: 본인 알림 목록 + 자동 읽음 처리" do
    sign_in_as(@user)
    assert_predicate Notification.unread.where(recipient: @user).count, :positive?

    get notifications_path

    assert_response :success
    assert_equal 0, Notification.unread.where(recipient: @user).count
  end

  test "read_all: 모든 알림 읽음 처리" do
    sign_in_as(@user)
    Notification.where(recipient: @user).update_all(read_at: nil)
    assert_predicate Notification.unread.where(recipient: @user).count, :positive?

    patch read_all_notifications_path

    assert_redirected_to notifications_path
    assert_equal 0, Notification.unread.where(recipient: @user).count
  end
end
