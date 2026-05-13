class Downvote < ApplicationRecord
  belongs_to :from_user,   class_name: "User"
  belongs_to :to_user,     class_name: "User"
  belongs_to :red_connect

  # false_info / abusive: 스코어 페널티 적용
  # incompatible: 페널티 없음(취향 차이) — 해제만
  enum :kind, { false_info: 0, abusive: 1, incompatible: 2 }

  validates :kind, presence: true
  validate  :from_user_in_red_connect
  validate  :to_user_in_red_connect
  validate  :from_and_to_differ

  after_create_commit :apply_consequences

  PENALTY_KINDS = %w[ false_info abusive ].freeze

  private
    def from_user_in_red_connect
      return if red_connect.blank? || from_user.blank?
      ok = from_user.id == red_connect.user_a_id || from_user.id == red_connect.user_b_id
      errors.add(:from_user, "는 이 커넥트의 구성원이 아닙니다") unless ok
    end

    def to_user_in_red_connect
      return if red_connect.blank? || to_user.blank?
      ok = to_user.id == red_connect.user_a_id || to_user.id == red_connect.user_b_id
      errors.add(:to_user, "는 이 커넥트의 구성원이 아닙니다") unless ok
    end

    def from_and_to_differ
      errors.add(:to_user, "는 본인과 달라야 합니다") if from_user_id == to_user_id
    end

    # 1) RedConnect 자동 해제 (사유 무관)
    # 2) 페널티 사유면 ScoreEvent 생성 (-config.downvote_penalty 적용)
    # 3) 페널티 사유면 to_user에게 'downvoted' 알림
    def apply_consequences
      red_connect.release!(reason: "downvote:#{kind}") if red_connect.active?
      return unless PENALTY_KINDS.include?(kind)

      delta = Rails.application.config.x.blackticket.downvote_penalty
      to_user.score_events.create!(delta: delta, reason: :downvoted_self,
                                   related: self, memo: "비추천: #{kind}")
      Notification.create!(recipient: to_user, actor: from_user,
                           action: "downvoted", notifiable: self)
    end
end
