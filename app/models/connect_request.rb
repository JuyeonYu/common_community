class ConnectRequest < ApplicationRecord
  belongs_to :requester, class_name: "User"
  belongs_to :target,    class_name: "User"

  enum :status, { pending: 0, accepted: 1, rejected: 2, cancelled: 3, expired: 4 }

  validates :gen_week, presence: true
  validate  :no_self_request
  validate  :one_pending_per_week, on: :create

  scope :recent, -> { order(created_at: :desc) }

  before_validation :assign_gen_week, on: :create
  after_create_commit :notify_target

  # 본인이 요청 수락 시 트랜잭션:
  # 1) 본인 status=accepted
  # 2) RedConnect 생성 (1개월 만료)
  # 3) 본인이 보낸/받은 다른 pending 요청 자동 취소 (기획서 4-4)
  def accept!
    transaction do
      update!(status: :accepted)
      RedConnect.between(requester, target).first_or_create!(
        user_a: requester, user_b: target,
        expires_at: Rails.application.config.x.blackticket.red_connect_default_ttl.from_now
      )
      cancel_other_pending!(target)
      cancel_other_pending!(requester)
      Notification.deliver(recipient: requester, actor: target,
                           action: "connect_accepted", notifiable: self)
    end
  end

  def reject!
    transaction do
      update!(status: :rejected)
      refund_retry_if_applicable
    end
    Notification.deliver(recipient: requester, actor: target,
                         action: "connect_rejected", notifiable: self)
  end

  def cancel!
    update!(status: :cancelled)
  end

  def self.current_gen_week
    Date.current.strftime("%GW%V")
  end

  # "2026W20" → 해당 ISO 주의 월요일 00:00 ~ 일요일 23:59 범위.
  def self.gen_week_range(gen_week)
    year, week = gen_week.split("W").map(&:to_i)
    Date.commercial(year, week, 1).beginning_of_day..Date.commercial(year, week, 7).end_of_day
  end

  private
    def assign_gen_week
      self.gen_week ||= self.class.current_gen_week
    end

    def no_self_request
      errors.add(:target, "본인에게는 요청할 수 없습니다") if requester_id == target_id
    end

    def one_pending_per_week
      return if requester_id.blank? || gen_week.blank?
      already = self.class.where(requester_id: requester_id, gen_week: gen_week, status: :pending).exists?
      errors.add(:base, "이번 기수에 이미 요청을 보냈습니다") if already
    end

    def cancel_other_pending!(user)
      self.class.where(status: :pending)
                .where("requester_id = :id OR target_id = :id", id: user.id)
                .where.not(id: id)
                .update_all(status: self.class.statuses[:cancelled])
    end

    def notify_target
      Notification.deliver(
        recipient: target, actor: requester,
        action: "connect_requested", notifiable: self
      )
    end

    # 재요청이 거절된 경우 요청자에게 50% 환급 (v1.2 7-4).
    def refund_retry_if_applicable
      return unless retried?
      cost   = Rails.application.config.x.blackticket.connect_retry_cost
      refund = (cost * 0.5).to_i
      return if refund <= 0
      requester.credit_transactions.create!(
        amount: refund, kind: :refund, related: self, memo: "connect_retry_refund"
      )
    end
end
