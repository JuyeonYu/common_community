class InvitationsController < ApplicationController
  # /i/:code 진입은 비로그인도 가능 (세션에 저장 후 OAuth로 이어짐).
  allow_unauthenticated_access only: :show
  # 잠금 사용자가 코드 입력하기 위한 화면들.
  allow_inactive_access only: %i[ redeem apply_redemption ]

  # 활성 사용자의 초대 목록 + 발급 폼.
  def index
    @invitations  = Current.user.sent_invitations.order(created_at: :desc).limit(50)
    @invitation   = Invitation.new
    @next_free_at = next_free_invitation_at
  end

  # 새 초대 발급. 7일 1회 무료, 그 외엔 향후 크레딧 소비 (Phase E).
  def create
    if next_free_invitation_at&.future?
      redirect_to invitations_path, alert: "무료 초대는 #{l next_free_invitation_at, format: :short} 이후 가능합니다." and return
    end

    @invitation = Current.user.sent_invitations.create!(
      recommendation_comment: params.dig(:invitation, :recommendation_comment).to_s.presence
    )
    redirect_to invitations_path, notice: "초대 코드 #{@invitation.code} 가 생성되었습니다."
  end

  # 본인이 보낸 pending 초대 취소.
  def destroy
    invitation = Current.user.sent_invitations.find(params[:id])
    invitation.cancel! if invitation.pending?
    redirect_to invitations_path, notice: "초대를 취소했습니다."
  end

  # /i/:code 진입.
  def show
    invitation = Invitation.find_by(code: params[:code])

    unless invitation&.usable?
      redirect_to root_path, alert: "유효하지 않거나 만료된 초대 코드입니다." and return
    end

    if Current.user
      # 로그인 사용자: 활성이면 안내, 비활성이면 즉시 적용.
      if Current.user.active?
        redirect_to root_path, notice: "이미 활성 상태입니다."
      else
        invitation.redeem!(Current.user)
        redirect_to root_path, notice: "초대 코드가 적용되었습니다."
      end
    else
      # 비로그인: 세션에 저장 후 Google OAuth로.
      session[:pending_invitation_code] = invitation.code
      redirect_to new_session_path, notice: "초대장을 확인했습니다. 구글 계정으로 가입을 진행해주세요."
    end
  end

  # 잠금 사용자가 보는 코드 입력 폼.
  def redeem
  end

  def apply_redemption
    code = params[:code].to_s.strip.upcase
    invitation = Invitation.find_by(code: code)

    if invitation&.usable?
      invitation.redeem!(Current.user)
      redirect_to root_path, notice: "초대 코드가 적용되었습니다."
    else
      flash.now[:alert] = "유효하지 않거나 만료된 초대 코드입니다."
      render :redeem, status: :unprocessable_entity
    end
  end

  private
    def next_free_invitation_at
      last = Current.user.sent_invitations.order(created_at: :desc).first
      return nil unless last
      last.created_at + 7.days
    end
end
