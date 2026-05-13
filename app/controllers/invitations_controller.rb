require "set"

class InvitationsController < ApplicationController
  # /i/:code 진입은 비로그인도 가능 (세션에 저장 후 OAuth로 이어짐).
  allow_unauthenticated_access only: :show
  # 잠금 사용자가 코드 입력하기 위한 화면들.
  allow_inactive_access only: %i[ redeem apply_redemption ]

  TREE_MAX_DEPTH = 5

  # 활성 사용자의 초대 목록 + 발급 폼 + 초대 트리.
  def index
    @invitations  = Current.user.sent_invitations.order(created_at: :desc).limit(50)
    @invitation   = Invitation.new
    @next_free_at = next_free_invitation_at
    @inviter      = Current.user.invited_by
    @tree_root    = build_invitee_tree(Current.user, depth: 0)
    @tree_stats   = collect_tree_stats(@tree_root)
  end

  # 새 초대 발급. 7일 1회 무료, 그 외엔 향후 크레딧 소비(Phase E).
  # boosted=true면 즉시 크레딧 차감.
  def create
    if next_free_invitation_at&.future?
      redirect_to invitations_path, alert: "무료 초대는 #{l next_free_invitation_at, format: :short} 이후 가능합니다." and return
    end

    boosted = ActiveModel::Type::Boolean.new.cast(params.dig(:invitation, :boosted))
    cost    = Rails.application.config.x.blackticket.boosted_invitation_cost
    if boosted && Current.user.ticket_credits < cost
      redirect_to invitations_path, alert: "강력 추천에 필요한 크레딧이 부족합니다 (#{cost} 필요)." and return
    end

    Invitation.transaction do
      @invitation = Current.user.sent_invitations.create!(
        invitee_email: params.dig(:invitation, :invitee_email).to_s,
        recommendation_comment: params.dig(:invitation, :recommendation_comment).to_s.strip,
        boosted: !!boosted
      )
      if boosted
        Current.user.credit_transactions.create!(
          amount: -cost, kind: :spend, related: @invitation, memo: "강력 추천"
        )
      end
    end
    InvitationMailJob.perform_later(@invitation.id)
    redirect_to invitations_path,
      notice: "초대 메일을 #{@invitation.invitee_email}로 발송했습니다." + (boosted ? " (강력 추천 -#{cost} 크레딧)" : "")
  rescue ActiveRecord::RecordInvalid => e
    redirect_to invitations_path, alert: e.record.errors.full_messages.first
  end

  # 같은 초대장 메일 재발송 (pending + 미만료).
  def resend
    invitation = Current.user.sent_invitations.find(params[:id])
    if invitation.usable?
      InvitationMailJob.perform_later(invitation.id)
      redirect_to invitations_path, notice: "초대 메일을 재발송했습니다."
    else
      redirect_to invitations_path, alert: "재발송할 수 없는 초대입니다."
    end
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
      # 로그인 사용자: 활성이면 안내, 비활성이면 이메일 검증 후 적용.
      if Current.user.active?
        redirect_to root_path, notice: "이미 활성 상태입니다."
      elsif invitation.matches_email?(Current.user.email_address)
        invitation.redeem!(Current.user)
        redirect_to root_path, notice: "초대 코드가 적용되었습니다."
      else
        redirect_to redeem_invitations_path,
          alert: "초대받은 이메일(#{invitation.invitee_email})과 로그인 이메일이 일치하지 않습니다."
      end
    else
      # 비로그인: 세션에 저장 후 Google OAuth로.
      session[:pending_invitation_code]  = invitation.code
      session[:pending_invitee_email]    = invitation.invitee_email
      redirect_to new_session_path, notice: "초대장을 확인했습니다. 구글 계정으로 가입을 진행해주세요."
    end
  end

  # 잠금 사용자가 보는 코드 입력 폼.
  def redeem
  end

  def apply_redemption
    code = params[:code].to_s.strip.upcase
    invitation = Invitation.find_by(code: code)

    unless invitation&.usable?
      flash.now[:alert] = "유효하지 않거나 만료된 초대 코드입니다."
      render :redeem, status: :unprocessable_entity and return
    end

    unless invitation.matches_email?(Current.user.email_address)
      flash.now[:alert] = "이 초대 코드는 다른 이메일(#{invitation.invitee_email})에게 발급되었습니다."
      render :redeem, status: :unprocessable_entity and return
    end

    invitation.redeem!(Current.user)
    redirect_to root_path, notice: "초대 코드가 적용되었습니다."
  end

  private
    def next_free_invitation_at
      last = Current.user.sent_invitations.order(created_at: :desc).first
      return nil unless last
      last.created_at + 7.days
    end

    # 본인 → 본인이 초대한 사람들 → 그들이 초대한 사람들 ... 재귀.
    # 깊이 제한과 visited 셋으로 사이클·과도 노드 방지.
    def build_invitee_tree(user, depth:, visited: Set.new)
      return { user: user, children: [], truncated: true } if depth >= TREE_MAX_DEPTH
      return { user: user, children: [], cycle: true } if visited.include?(user.id)

      visited = visited + [ user.id ]
      children = user.invitees.order(:created_at).map do |child|
        build_invitee_tree(child, depth: depth + 1, visited: visited)
      end
      { user: user, children: children }
    end

    def collect_tree_stats(node)
      total = 0
      max_depth = 0
      walker = ->(n, d) {
        n[:children].each do |child|
          total += 1
          max_depth = d + 1 if d + 1 > max_depth
          walker.call(child, d + 1)
        end
      }
      walker.call(node, 0)
      { descendants: total, max_depth: max_depth }
    end
end
