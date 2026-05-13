class ChatMessage < ApplicationRecord
  include Reportable

  # 본문 내 이미지 URL 차단 패턴(자주 쓰는 확장자).
  IMAGE_URL_PATTERN = %r{https?://\S+\.(?:jpe?g|png|gif|webp|bmp|svg|heic)\b}i

  belongs_to :red_connect
  belongs_to :sender, class_name: "User"

  validates :body, presence: true, length: { in: 1..1000 }
  validate  :red_connect_must_be_active
  validate  :sender_must_be_in_connect
  validate  :no_image_url_in_body

  scope :recent, -> { order(created_at: :asc) }

  after_create_commit :broadcast_to_room
  after_create_commit :enqueue_web_push

  def recipient
    red_connect.other_user(sender)
  end

  private
    def red_connect_must_be_active
      return if red_connect.blank?
      errors.add(:base, "이 커넥트는 종료되어 메시지를 보낼 수 없습니다") unless red_connect.active?
    end

    def sender_must_be_in_connect
      return if red_connect.blank? || sender.blank?
      ok = sender.id == red_connect.user_a_id || sender.id == red_connect.user_b_id
      errors.add(:sender, "는 이 커넥트의 구성원이 아닙니다") unless ok
    end

    def no_image_url_in_body
      return if body.blank?
      errors.add(:body, "에 이미지 URL은 보낼 수 없습니다") if body.match?(IMAGE_URL_PATTERN)
    end

    def broadcast_to_room
      broadcast_append_to red_connect, target: dom_id(red_connect, :messages),
        partial: "chat_messages/chat_message", locals: { chat_message: self }
    end

    def enqueue_web_push
      Notification.create!(
        recipient: recipient, actor: sender,
        action: "chat_message", notifiable: self
      )
    end

    def dom_id(*args)
      ActionView::RecordIdentifier.dom_id(*args)
    end
end
