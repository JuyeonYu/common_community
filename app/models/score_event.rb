class ScoreEvent < ApplicationRecord
  belongs_to :user
  belongs_to :related, polymorphic: true, optional: true

  enum :reason, {
    admin_adjust:       0,   # admin이 직접 조정
    invitee_active_3m:  10,  # 피초대자 3개월 활동 → +1 (Phase D)
    invitee_suspended:  20,  # 피초대자 정지 → -3 (Phase D)
    downvoted_self:     30,  # 비추천 누적 3회 → -5 (Phase D)
    downvoted_inviter:  31,  # 비추천 받은 사람의 초대자 → -3 (Phase D)
    other:              99
  }

  validates :delta, presence: true, numericality: { only_integer: true }
  validates :reason, presence: true

  # 이력 생성 후 user의 누적 스코어를 갱신하고, 0 이하면 정지 처리.
  after_create_commit :apply_to_user

  scope :recent, -> { order(created_at: :desc) }

  private
    def apply_to_user
      user.with_lock do
        user.update!(ticket_score: user.ticket_score + delta)
        user.suspend!(reason: "ticket_score_zero") if user.ticket_score <= 0 && !user.suspended?
      end
    end
end
