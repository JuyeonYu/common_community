class InvitationMailer < ApplicationMailer
  def invite(invitation)
    @invitation = invitation
    @inviter    = invitation.inviter
    @invite_url = invite_link_url(code: invitation.code)

    mail(
      to:      invitation.invitee_email,
      subject: "[블랙티켓] #{@inviter.nickname.presence || @inviter.name}님의 초대장이 도착했습니다"
    )
  end
end
