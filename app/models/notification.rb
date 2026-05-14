class Notification < ApplicationRecord
  # Phase D-0: 게시판 부활로 댓글/좋아요 알림 재도입.
  # Phase E-2: 매칭/커넥트 누락 알림(new_match_exposed, connect_rejected) + 멘션(mentioned) 추가.
  ACTIONS = %w[
    commented_on_post replied_to_comment liked_post liked_comment
    connect_requested connect_accepted connect_cancelled connect_released connect_rejected
    new_match_exposed
    chat_message downvoted mentioned
    recommendation_requested recommendation_written
  ].freeze

  belongs_to :recipient, class_name: "User"
  belongs_to :actor, class_name: "User", optional: true
  belongs_to :notifiable, polymorphic: true

  validates :action, inclusion: { in: ACTIONS }
  validates :action, presence: true

  scope :unread, -> { where(read_at: nil) }
  scope :read,   -> { where.not(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }

  after_create_commit :broadcast_to_recipient
  after_create_commit :enqueue_web_push

  # 그룹화 알림 디스패처. group_key가 같고 read_at=nil인 알림이 이미 있으면 새로 만들지 않고
  # count만 증가시켜 카드 교체로 broadcast. 그 외엔 일반 create와 동등.
  def self.deliver(recipient:, actor:, action:, notifiable:, group_key: nil)
    return nil if recipient.nil? || recipient == actor

    if group_key.present?
      existing = where(recipient: recipient, group_key: group_key, read_at: nil).first
      if existing
        existing.with_lock do
          existing.update_columns(
            count: existing.count + 1,
            actor_id: actor&.id || existing.actor_id,
            notifiable_type: notifiable.class.name,
            notifiable_id: notifiable.id,
            updated_at: Time.current
          )
        end
        existing.broadcast_replace_card
        existing.enqueue_web_push
        return existing
      end
    end

    create!(recipient: recipient, actor: actor, action: action,
            notifiable: notifiable, group_key: group_key)
  end

  def read?
    read_at.present?
  end

  def message
    suffix = count > 1 ? " (#{count})" : ""
    body = I18n.t("notifications.actions.#{action}", default: "")
    "#{body}#{suffix}"
  end

  def link_path
    helpers = Rails.application.routes.url_helpers
    case notifiable
    when Post           then notifiable
    when Comment        then notifiable.post
    when ConnectRequest then helpers.matching_path
    when RedConnect     then helpers.red_connect_path(notifiable)
    when ChatMessage    then helpers.red_connect_path(notifiable.red_connect)
    when Downvote       then helpers.matching_path
    when MatchExposure  then helpers.matching_path
    when Invitation
      # 추천서 요청 → 초대자가 작성하러 갈 곳 / 추천서 작성됨 → 피초대자가 매칭으로
      if action == "recommendation_requested"
        helpers.edit_invitation_path(notifiable)
      else
        helpers.matching_path
      end
    end
  end

  def broadcast_replace_card
    broadcast_replace_to [ recipient, :notifications ],
      target: ActionView::RecordIdentifier.dom_id(self),
      partial: "notifications/notification",
      locals: { notification: self }
    recipient.broadcast_notification_badge
  end

  def enqueue_web_push
    WebPushJob.perform_later(id)
  end

  private
    def broadcast_to_recipient
      broadcast_prepend_to [ recipient, :notifications ],
        target: "notifications_list",
        partial: "notifications/notification",
        locals: { notification: self }

      recipient.broadcast_notification_badge
    end
end
