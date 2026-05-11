class InvitationMailer < ApplicationMailer
  default from: "noreply@blackticket.example"

  def invite(invitation)
    @invitation = invitation
    @invite_url = signup_url(token: invitation.token)
    mail to: invitation.invitee_email,
         subject: "[Black Ticket] #{invitation.inviter.name}님이 보낸 초대장"
  end
end
