class MatchExposure < ApplicationRecord
  belongs_to :viewer, class_name: "User"
  belongs_to :target, class_name: "User"

  validates :viewer_id, uniqueness: { scope: :target_id }

  after_create_commit :notify_viewer

  private
    # 이번 기수에 추가된 신규 노출 — group_key로 묶어 1알림 + count 증가.
    def notify_viewer
      Notification.deliver(
        recipient: viewer, actor: target,
        action: "new_match_exposed", notifiable: self,
        group_key: "match_exposure:#{viewer_id}:#{ConnectRequest.current_gen_week}"
      )
    end
end
