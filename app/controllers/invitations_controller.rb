require "set"

class InvitationsController < ApplicationController
  # /i/:code 진입은 비로그인도 가능 (세션에 저장 후 OAuth로 이어짐).
  allow_unauthenticated_access only: :show

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

  # 새 초대 발급. 이메일만 입력 — 추천서/강력 추천은 가입 후 별도 작성.
  def create
    if next_free_invitation_at&.future?
      redirect_to invitations_path, alert: "무료 초대는 #{l next_free_invitation_at, format: :short} 이후 가능합니다." and return
    end

    local_part = params.dig(:invitation, :invitee_local_part).to_s.strip
    @invitation = Current.user.sent_invitations.create!(
      invitee_email: local_part.present? ? "#{local_part}@gmail.com" : ""
    )
    InvitationMailJob.perform_later(@invitation.id)
    redirect_to invitations_path, notice: "초대 메일을 #{@invitation.invitee_email}로 발송했습니다."
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

  # 추천서 작성 폼 (가입한 invitee에 대해서만 의미 있음).
  def edit
    @invitation = Current.user.sent_invitations.find(params[:id])
    if @invitation.recommendation_written?
      redirect_to invitations_path, alert: "이미 작성된 추천서는 수정할 수 없습니다." and return
    end
    @boost_cost = Rails.application.config.x.blackticket.boosted_invitation_cost
  end

  # 추천서 + (선택)강력 추천 저장. 첫 작성만 허용.
  def update
    @invitation = Current.user.sent_invitations.find(params[:id])
    if @invitation.recommendation_written?
      redirect_to invitations_path, alert: "이미 작성된 추천서는 수정할 수 없습니다." and return
    end

    boosted = ActiveModel::Type::Boolean.new.cast(params.dig(:invitation, :boosted))
    cost    = Rails.application.config.x.blackticket.boosted_invitation_cost
    if boosted && Current.user.ticket_credits < cost
      redirect_to edit_invitation_path(@invitation),
        alert: "강력 추천에 필요한 크레딧이 부족합니다 (#{cost} 필요)." and return
    end

    Invitation.transaction do
      @invitation.update!(
        recommendation_comment: params.dig(:invitation, :recommendation_comment).to_s.strip,
        boosted: !!boosted
      )
      if boosted
        Current.user.credit_transactions.create!(
          amount: -cost, kind: :spend, related: @invitation, memo: "강력 추천"
        )
      end
      # 피초대자가 가입한 상태면 알림 발송.
      if @invitation.accepted_by
        Notification.deliver(
          recipient: @invitation.accepted_by, actor: Current.user,
          action: "recommendation_written", notifiable: @invitation
        )
      end
    end
    redirect_to invitations_path,
      notice: "추천서를 작성했습니다." + (boosted ? " (강력 추천 -#{cost} 크레딧)" : "")
  rescue ActiveRecord::RecordInvalid => e
    redirect_to edit_invitation_path(@invitation), alert: e.record.errors.full_messages.first
  end

  # 피초대자가 초대자에게 추천서 요청 (알림 발송).
  def request_recommendation
    @invitation = Current.user.accepted_invitation
    unless @invitation
      redirect_to matching_path, alert: "초대장 정보를 찾을 수 없습니다." and return
    end
    if @invitation.recommendation_written?
      redirect_to matching_path, notice: "이미 추천서가 작성되어 있습니다." and return
    end
    Notification.deliver(
      recipient: @invitation.inviter, actor: Current.user,
      action: "recommendation_requested", notifiable: @invitation
    )
    redirect_to matching_path, notice: "초대자에게 추천서 작성을 요청했습니다."
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
      # 활성 사용자만 로그인 상태로 유지되는 새 흐름. 그래도 fallback으로 active? 확인.
      redirect_to root_path, notice: "이미 활성 상태입니다."
    else
      # 비로그인: 세션에 저장 후 Google OAuth로.
      session[:pending_invitation_code]  = invitation.code
      session[:pending_invitee_email]    = invitation.invitee_email
      redirect_to new_session_path, notice: "초대장을 확인했습니다. 구글 계정으로 가입을 진행해주세요."
    end
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
