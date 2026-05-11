class WebPushJob < ApplicationJob
  queue_as :default

  # 한 Notification을 recipient의 모든 push_subscriptions로 발송.
  # WebPush 서버 응답이 410/404면 그 subscription을 영구 무효로 보고 삭제.
  def perform(notification_id)
    notification = Notification.find_by(id: notification_id)
    return unless notification

    vapid = Rails.application.credentials.vapid
    return unless vapid&.dig(:public_key).present? && vapid&.dig(:private_key).present?

    payload = build_payload(notification)

    notification.recipient.push_subscriptions.find_each do |sub|
      WebPush.payload_send(
        message: payload.to_json,
        endpoint: sub.endpoint,
        p256dh:   sub.p256dh_key,
        auth:     sub.auth_key,
        vapid: {
          subject:     vapid[:subject].presence || "mailto:noreply@example.com",
          public_key:  vapid[:public_key],
          private_key: vapid[:private_key]
        },
        ttl: 24 * 60 * 60
      )
    rescue WebPush::ExpiredSubscription, WebPush::InvalidSubscription
      sub.destroy
    rescue WebPush::ResponseError => e
      Rails.logger.warn("[WebPush] #{sub.endpoint} → #{e.response&.code}: #{e.message}")
    end
  end

  private
    def build_payload(notification)
      title = notification.actor&.name.presence || "Jiindo"
      {
        title: title,
        body:  notification.message,
        url:   url_for(notification.link_path),
        tag:   "notification-#{notification.id}"
      }
    end

    def url_for(notifiable)
      return "/" if notifiable.blank?
      Rails.application.routes.url_helpers.polymorphic_url(
        notifiable,
        host: default_host
      )
    end

    def default_host
      ActionMailer::Base.default_url_options[:host] || "localhost:3000"
    end
end
