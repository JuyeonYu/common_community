require "base64"
require "openssl"

# PortOne V2 웹훅 — Standard Webhooks 사양으로 서명 검증.
# 결제 누락(브라우저 단계 끊김) 대비 — Transaction.Paid 수신 시 CreditPurchase fulfill 보정.
class Webhooks::PortoneController < ApplicationController
  allow_unauthenticated_access
  skip_before_action :verify_authenticity_token, only: :create
  skip_before_action :ensure_nickname, only: :create

  def create
    body = request.body.read
    unless verify_signature(body)
      Rails.logger.warn "[PortOne webhook] signature verify failed"
      head :unauthorized and return
    end

    payload = JSON.parse(body)
    case payload["type"]
    when "Transaction.Paid"
      handle_paid(payload["data"] || {})
    when "Transaction.Cancelled", "Transaction.PartialCancelled"
      handle_cancelled(payload["data"] || {})
    end

    head :ok
  rescue JSON::ParserError
    head :bad_request
  end

  private
    # Standard Webhooks: webhook-id, webhook-timestamp, webhook-signature(v1,base64sig)
    def verify_signature(body)
      secret = PortOne.webhook_secret
      return false if secret.blank?

      id        = request.headers["webhook-id"]
      timestamp = request.headers["webhook-timestamp"]
      sig_header = request.headers["webhook-signature"].to_s

      return false if id.blank? || timestamp.blank? || sig_header.blank?

      signed = "#{id}.#{timestamp}.#{body}"
      key    = decode_secret(secret)
      digest = OpenSSL::HMAC.digest("SHA256", key, signed)
      expected = "v1,#{Base64.strict_encode64(digest)}"

      sig_header.split(" ").any? { |s| ActiveSupport::SecurityUtils.secure_compare(s, expected) }
    end

    # 시크릿 형식: "whsec_BASE64..." 또는 평문. PortOne은 평문 권장.
    def decode_secret(secret)
      if secret.start_with?("whsec_")
        Base64.strict_decode64(secret.sub("whsec_", ""))
      else
        secret
      end
    end

    def handle_paid(data)
      payment_id = data["paymentId"]
      return if payment_id.blank?
      purchase = CreditPurchase.find_by(external_payment_id: payment_id)
      return if purchase&.fulfilled? # 이미 처리됨

      if purchase.present? && purchase.pending?
        # 브라우저 단계에서 fulfill이 누락된 경우 보정
        purchase.fulfill!(by: purchase.user, memo: "PortOne 웹훅 보정")
      end
    end

    def handle_cancelled(data)
      payment_id = data["paymentId"]
      return if payment_id.blank?
      purchase = CreditPurchase.find_by(external_payment_id: payment_id)
      return unless purchase&.fulfilled?
      # MVP에선 환불은 운영자 수동 보정 — 로그만 남김.
      Rails.logger.warn "[PortOne webhook] payment cancelled but already fulfilled: id=#{payment_id} purchase_id=#{purchase.id}"
    end
end
