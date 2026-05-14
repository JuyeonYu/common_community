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
  validate  :resulting_balance_not_negative

  after_create_commit :apply_to_user

  scope :recent, -> { order(created_at: :desc) }

  private
    # ticket_credits는 잔액 캐시일 뿐 사용자 검증과 무관 — update_columns로 검증/콜백 건너뜀.
    # 잔액 음수 방지는 본 모델의 resulting_balance_not_negative 검증으로 보장한다.
    def apply_to_user
      user.with_lock do
        user.update_columns(ticket_credits: user.ticket_credits + amount, updated_at: Time.current)
      end
    end

    def resulting_balance_not_negative
      return unless user && amount
      if user.ticket_credits + amount < 0
        errors.add(:amount, "차감 후 잔액이 음수가 될 수 없습니다")
      end
    end
end
