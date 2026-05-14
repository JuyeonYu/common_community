class Notification < ApplicationRecord
  # Phase D-0: 게시판 부활로 댓글/좋아요 알림 재도입.
  # Phase D-1~D-3에서 매칭/커넥트/채팅/비추천 등 추가 예정.
  ACTIONS = %w[
    commented_on_post replied_to_comment liked_post liked_comment
    connect_requested connect_accepted connect_cancelled connect_released
    chat_message downvoted
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

  def read?
    read_at.present?
  end

  def message
    case action
    when "commented_on_post"  then "내 글에 댓글을 남겼습니다"
    when "replied_to_comment" then "내 댓글에 답글을 남겼습니다"
    when "liked_post"         then "내 글에 좋아요를 눌렀습니다"
    when "liked_comment"      then "내 댓글에 좋아요를 눌렀습니다"
    when "connect_requested"  then "커넥트를 요청했습니다"
    when "connect_accepted"   then "커넥트 요청을 수락했습니다"
    when "connect_cancelled"  then "커넥트 요청이 취소되었습니다"
    when "connect_released"   then "커넥트가 종료되었습니다"
    when "chat_message"       then "새 메시지를 보냈습니다"
    when "downvoted"          then "당신을 별로에요로 표시했습니다"
    when "recommendation_requested" then "추천서 작성을 요청했습니다"
    when "recommendation_written"   then "추천서를 작성해주었습니다"
    end
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
    when Invitation
      # 추천서 요청 → 초대자가 작성하러 갈 곳 / 추천서 작성됨 → 피초대자가 매칭으로
      if action == "recommendation_requested"
        helpers.edit_invitation_path(notifiable)
      else
        helpers.matching_path
      end
    end
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
