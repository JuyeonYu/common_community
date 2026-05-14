class Like < ApplicationRecord
  belongs_to :user
  belongs_to :likeable, polymorphic: true, counter_cache: false

  validates :user_id, uniqueness: { scope: %i[ likeable_type likeable_id ] }

  after_create_commit :create_notification

  private
    def create_notification
      return if likeable.user_id == user_id

      action, group_key = case likeable
      when Post    then [ "liked_post",    "post:#{likeable.id}:like" ]
      when Comment then [ "liked_comment", "comment:#{likeable.id}:like" ]
      end
      return unless action

      Notification.deliver(recipient: likeable.user, actor: user, action: action,
                           notifiable: likeable, group_key: group_key)
    end
end
