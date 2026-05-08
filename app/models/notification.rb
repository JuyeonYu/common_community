class Notification < ApplicationRecord
  ACTIONS = %w[ commented_on_post replied_to_comment liked_post liked_comment ].freeze

  belongs_to :recipient, class_name: "User"
  belongs_to :actor, class_name: "User", optional: true
  belongs_to :notifiable, polymorphic: true

  validates :action, inclusion: { in: ACTIONS }

  scope :unread, -> { where(read_at: nil) }
  scope :read,   -> { where.not(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }

  after_create_commit :broadcast_to_recipient

  def read?
    read_at.present?
  end

  def message
    case action
    when "commented_on_post"  then "내 글에 댓글을 남겼습니다"
    when "replied_to_comment" then "내 댓글에 답글을 남겼습니다"
    when "liked_post"         then "내 글에 좋아요를 눌렀습니다"
    when "liked_comment"      then "내 댓글에 좋아요를 눌렀습니다"
    end
  end

  def link_path
    case notifiable
    when Post    then notifiable
    when Comment then notifiable.post
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
end
