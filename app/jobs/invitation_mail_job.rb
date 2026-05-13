class InvitationMailJob < ApplicationJob
  queue_as :default

  # pending + 미만료 일 때만 발송. expired/accepted/cancelled는 무시(레이스 컨디션 방어).
  def perform(invitation_id)
    invitation = Invitation.find_by(id: invitation_id)
    return unless invitation&.usable?
    InvitationMailer.invite(invitation).deliver_now
  end
end
