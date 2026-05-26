# PortOne V2 통합 헬퍼.
# - 식별자: Store ID / Channel Key는 클라(JS) 노출 OK. API Secret / Webhook Secret은 서버 전용.
# - credentials.yml.enc → ENV 폴백 (dev에서 빠르게 테스트 가능).
# - 외부 의존성 없이 Net::HTTP만 사용 — 호출 빈도 낮고 페이로드 단순해서 gem 불필요.
require "net/http"
require "json"

module PortOne
  API_BASE = "https://api.portone.io".freeze

  module_function

  def store_id
    fetch(:store_id) || ENV["PORTONE_STORE_ID"]
  end

  def channel_key_identity
    fetch(:channel_key_identity) || ENV["PORTONE_CHANNEL_KEY_IDENTITY"]
  end

  def channel_key_payment
    fetch(:channel_key_payment) || ENV["PORTONE_CHANNEL_KEY_PAYMENT"]
  end

  def api_secret
    fetch(:api_secret) || ENV["PORTONE_V2_API_SECRET"]
  end

  def webhook_secret
    fetch(:webhook_secret) || ENV["PORTONE_WEBHOOK_SECRET"]
  end

  # 콘솔 설정이 모두 들어왔는지 — 본인인증/결제 진입 화면에서 안내용으로 검사.
  def configured?
    store_id.present? && api_secret.present?
  end

  def identity_enabled?
    configured? && channel_key_identity.present?
  end

  def payment_enabled?
    configured? && channel_key_payment.present?
  end

  # GET /identity-verifications/:id — 본인인증 결과 조회.
  def get_identity_verification(id)
    get("/identity-verifications/#{id}")
  end

  # GET /payments/:id — 결제 결과 조회.
  def get_payment(id)
    get("/payments/#{id}")
  end

  # --- 내부 ---

  def fetch(key)
    Rails.application.credentials.dig(:portone, key)
  end

  def get(path)
    uri = URI.join(API_BASE, path)
    req = Net::HTTP::Get.new(uri)
    req["Authorization"] = "PortOne #{api_secret}"
    req["Content-Type"]  = "application/json"

    res = Net::HTTP.start(uri.host, uri.port, use_ssl: true, read_timeout: 10, open_timeout: 5) do |http|
      http.request(req)
    end

    body = res.body.to_s
    json = body.present? ? JSON.parse(body) : {}
    [ res.code.to_i, json ]
  end
end
