require "test_helper"

class PushSubscriptionTest < ActiveSupport::TestCase
  test "유효한 구독" do
    sub = users(:one).push_subscriptions.build(
      endpoint: "https://example.com/push/unique",
      p256dh_key: "k",
      auth_key: "a"
    )
    assert sub.valid?
  end

  test "endpoint 중복 금지" do
    existing = push_subscriptions(:one_chrome)
    dup = users(:two).push_subscriptions.build(
      endpoint: existing.endpoint, p256dh_key: "k", auth_key: "a"
    )
    assert_not dup.valid?
    assert_includes dup.errors.attribute_names, :endpoint
  end

  test "필수 키 누락 시 invalid" do
    sub = users(:one).push_subscriptions.build(endpoint: "https://e", p256dh_key: nil, auth_key: nil)
    assert_not sub.valid?
    assert_includes sub.errors.attribute_names, :p256dh_key
    assert_includes sub.errors.attribute_names, :auth_key
  end
end
