class Notification < ApplicationRecord
  # Phase A: 커뮤니티 도메인 알림(comment/like 등)을 모두 폐기.
  # Phase B/C에서 새 도메인 이벤트(invitation_received 등)를 화이트리스트에 추가한다.
  ACTIONS = %w[].freeze

  belongs_to :recipient, class_name: "User"
  belongs_to :actor, class_name: "User", optional: true
  belongs_to :notifiable, polymorphic: true

  validates :action, inclusion: { in: ACTIONS }, if: -> { ACTIONS.any? }
  validates :action, presence: true

  scope :unread, -> { where(read_at: nil) }
  scope :read,   -> { where.not(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }

  after_create_commit :broadcast_to_recipient
  after_create_commit :enqueue_web_push

  def read?
    read_at.present?
  end

  def message
    "" # Phase B/C에서 action별 한글 문구 매핑 추가
  end

  def link_path
    # Phase B/C에서 notifiable별 경로 매핑 추가
    nil
  end

  private
    def broadcast_to_recipient
      broadcast_prepend_to [ recipient, :notifications ],
        target: "notifications_list",
        partial: "notifications/notification",
        locals: { notification: self }

      recipient.broadcast_notification_badge
    end

    def enqueue_web_push
      WebPushJob.perform_later(id)
    end
end
