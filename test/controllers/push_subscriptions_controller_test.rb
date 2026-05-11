require "test_helper"

class PushSubscriptionsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = users(:one) }

  test "create: 비로그인 차단" do
    post push_subscriptions_path, params: valid_params, as: :json
    assert_redirected_to new_session_path
  end

  test "create: 새 구독 등록" do
    sign_in_as(@user)
    assert_difference -> { @user.push_subscriptions.count }, +1 do
      post push_subscriptions_path, params: valid_params, as: :json
    end
    assert_response :created
  end

  test "create: 같은 endpoint 재요청 시 키만 갱신, 행 증가 없음" do
    sign_in_as(@user)
    existing = push_subscriptions(:one_chrome)

    assert_no_difference -> { PushSubscription.count } do
      post push_subscriptions_path,
        params: { push_subscription: { endpoint: existing.endpoint, p256dh_key: "new-p", auth_key: "new-a" } },
        as: :json
    end
    assert_equal "new-p", existing.reload.p256dh_key
  end

  test "unsubscribe: endpoint로 자기 구독 삭제" do
    sign_in_as(@user)
    sub = push_subscriptions(:one_chrome)

    assert_difference -> { @user.push_subscriptions.count }, -1 do
      delete unsubscribe_push_subscriptions_path,
        params: { endpoint: sub.endpoint }, as: :json
    end
    assert_response :no_content
  end

  test "unsubscribe: 남의 endpoint는 삭제 안 됨" do
    sign_in_as(@user)
    other = push_subscriptions(:two_safari)

    assert_no_difference -> { PushSubscription.count } do
      delete unsubscribe_push_subscriptions_path,
        params: { endpoint: other.endpoint }, as: :json
    end
  end

  private
    def valid_params
      {
        push_subscription: {
          endpoint: "https://fcm.googleapis.com/fcm/send/brand-new-#{SecureRandom.hex(4)}",
          p256dh_key: "p256dh-sample",
          auth_key: "auth-sample"
        }
      }
    end
end
