class Like < ApplicationRecord
  belongs_to :user
  belongs_to :likeable, polymorphic: true, counter_cache: false

  validates :user_id, uniqueness: { scope: %i[ likeable_type likeable_id ] }

  after_create_commit :create_notification

  private
    def create_notification
      return if likeable.user_id == user_id

      action = case likeable
      when Post    then "liked_post"
      when Comment then "liked_comment"
      end
      return unless action

      Notification.create!(recipient: likeable.user, actor: user, action: action, notifiable: likeable)
    end
end
