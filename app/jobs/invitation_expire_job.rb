class InvitationExpireJob < ApplicationJob
  queue_as :default

  # 만료 시각 지난 pending invitation을 expired로 마킹.
  def perform
    Invitation.where(status: :pending)
              .where("expires_at < ?", Time.current)
              .update_all(status: Invitation.statuses[:expired])
  end
end
