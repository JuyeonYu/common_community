class CreditPurchase < ApplicationRecord
  # 무통장입금 1건 = 입금 알리기 1건. 어드민이 실제 입금을 확인한 뒤 fulfill!로 크레딧 충전.
  # PG 도입 시 fulfill을 콜백으로 자동화하지만 본 모델은 그대로 재활용.

  belongs_to :user
  belongs_to :processed_by, class_name: "User", optional: true

  enum :status, { pending: 0, fulfilled: 1, rejected: 2, cancelled: 3 }

  validates :package_key, presence: true, inclusion: { in: CreditPackages::KEYS }
  validates :declared_amount, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :declared_name, presence: true, length: { in: 2..50 }

  scope :recent, -> { order(created_at: :desc) }

  def package
    CreditPackages.find(package_key)
  end

  def total_credits
    CreditPackages.total_credits_for(package_key)
  end

  def expected_price_won
    CreditPackages.price_for(package_key)
  end

  # 승인 — 트랜잭션으로 상태 갱신 + 크레딧 부여. CreditTransaction의 after_create_commit에서 잔액 자동 갱신.
  def fulfill!(by:, memo: nil)
    return false unless pending?
    transaction do
      update!(status: :fulfilled, processed_by: by, processed_at: Time.current, admin_memo: memo)
      user.credit_transactions.create!(
        amount: total_credits, kind: :purchase,
        related: self, memo: "입금 충전 (#{package_key})"
      )
    end
    true
  end

  def reject!(by:, memo: nil)
    return false unless pending?
    update!(status: :rejected, processed_by: by, processed_at: Time.current, admin_memo: memo)
    true
  end
end
