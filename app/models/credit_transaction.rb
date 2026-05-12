class CreditTransaction < ApplicationRecord
  belongs_to :user
  belongs_to :related, polymorphic: true, optional: true

  enum :kind, {
    signup_bonus:   0,   # 가입 시 자동 부여
    admin_grant:    1,   # admin 수동 충전
    admin_revoke:   2,   # admin 수동 차감
    spend:          10,  # 서비스 내 소비 (Phase D — boosted 초대, 매칭권 등)
    refund:         11,
    purchase:       20   # 결제 PG 충전 (Phase E)
  }

  validates :amount, presence: true, numericality: { only_integer: true }
  validates :kind, presence: true

  after_create_commit :apply_to_user

  scope :recent, -> { order(created_at: :desc) }

  private
    def apply_to_user
      user.with_lock do
        user.update!(ticket_credits: user.ticket_credits + amount)
      end
    end
end
