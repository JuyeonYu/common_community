class NotificationsController < ApplicationController
  def index
    @pagy, @notifications = pagy(
      Current.user.notifications.includes(:actor, :notifiable).recent,
      limit: 30
    )
    mark_all_read
  end

  def read_all
    mark_all_read
    redirect_to notifications_path
  end

  private
    def mark_all_read
      return if Current.user.notifications.unread.none?
      Current.user.notifications.unread.update_all(read_at: Time.current)
      Current.user.broadcast_notification_badge
    end
end
