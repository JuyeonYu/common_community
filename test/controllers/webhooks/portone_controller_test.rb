require "test_helper"
require "openssl"
require "base64"

class Webhooks::PortoneControllerTest < ActionDispatch::IntegrationTest
  SECRET = "test_secret_value".freeze

  setup do
    @user = users(:one)
    ENV["PORTONE_WEBHOOK_SECRET"] = SECRET
  end

  teardown { ENV.delete("PORTONE_WEBHOOK_SECRET") }

  def sign(body, id:, timestamp:)
    signed = "#{id}.#{timestamp}.#{body}"
    digest = OpenSSL::HMAC.digest("SHA256", SECRET, signed)
    "v1,#{Base64.strict_encode64(digest)}"
  end

  test "서명 누락 → 401" do
    post "/webhooks/portone", params: "{}", headers: { "Content-Type" => "application/json" }
    assert_response :unauthorized
  end

  test "잘못된 서명 → 401" do
    post "/webhooks/portone", params: '{"type":"Transaction.Paid"}',
         headers: {
           "Content-Type" => "application/json",
           "webhook-id" => "msg_1",
           "webhook-timestamp" => Time.current.to_i.to_s,
           "webhook-signature" => "v1,WRONG"
         }
    assert_response :unauthorized
  end

  test "유효 서명 + Transaction.Paid → 200 + 누락된 fulfill 보정" do
    purchase = @user.credit_purchases.create!(
      package_key: "starter", declared_amount: 4900, declared_name: "x",
      paid_via: :portone_card, external_payment_id: "payment-xyz"
    )
    body = { type: "Transaction.Paid", data: { paymentId: "payment-xyz" } }.to_json
    id   = "msg_1"
    ts   = Time.current.to_i.to_s

    post "/webhooks/portone", params: body,
         headers: {
           "Content-Type" => "application/json",
           "webhook-id" => id,
           "webhook-timestamp" => ts,
           "webhook-signature" => sign(body, id: id, timestamp: ts)
         }
    assert_response :ok
    assert purchase.reload.fulfilled?
  end
end
