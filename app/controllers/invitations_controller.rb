class InvitationsController < ApplicationController
  before_action :set_invitation, only: %i[ destroy ]

  def index
    @invitations = Current.user.sent_invitations.order(created_at: :desc).limit(50)
    @invitation = Invitation.new
  end

  def create
    @invitation = Current.user.sent_invitations.build(invitation_params)
    if @invitation.save
      InvitationMailer.invite(@invitation).deliver_later
      redirect_to invitations_path, notice: "초대장이 발송되었습니다."
    else
      @invitations = Current.user.sent_invitations.order(created_at: :desc).limit(50)
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    if @invitation.cancel!
      redirect_to invitations_path, notice: "초대를 취소했습니다.", status: :see_other
    else
      redirect_to invitations_path, alert: "이미 가입된 초대장은 취소할 수 없습니다."
    end
  end

  private
    def set_invitation
      @invitation = Current.user.sent_invitations.find_by!(token: params[:id])
    end

    def invitation_params
      params.expect(invitation: [ :invitee_name, :invitee_phone, :invitee_email ])
    end
end
