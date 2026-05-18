class InvitationExpireJob < ApplicationJob
  queue_as :default

  # 만료 시각 지난 pending invitation을 expired로 마킹.
  # paid_extra(크레딧 결제 발급)는 미가입 만료 시 발급자에게 50% 환급 (v1.2 7-4).
  def perform
    cost   = Rails.application.config.x.blackticket.invitation_extra_cost
    refund = (cost * 0.5).to_i

    Invitation.where(status: :pending)
              .where("expires_at < ?", Time.current)
              .find_each do |inv|
      inv.update_columns(status: Invitation.statuses[:expired])
      if inv.paid_extra? && refund > 0
        inv.inviter.credit_transactions.create!(
          amount: refund, kind: :refund, related: inv, memo: "invitation_extra_refund"
        )
      end
    end
  end
end
