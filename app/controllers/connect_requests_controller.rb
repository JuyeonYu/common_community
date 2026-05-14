class ConnectRequestsController < ApplicationController
  before_action :ensure_matching_active

  def create
    gen_week = ConnectRequest.current_gen_week
    target   = User.find(params[:target_id])

    if Current.user.had_red_connect_this_week?(gen_week)
      redirect_to matching_path,
        alert: "이번 기수에 이미 성사된 커넥트가 있어 새 요청이 불가합니다." and return
    end

    # 이미 본 기수에 요청을 한 번이라도 보낸 적이 있다면 재요청 흐름.
    prior_targets = Current.user.sent_connect_requests.where(gen_week: gen_week).pluck(:target_id)
    if prior_targets.any?
      if prior_targets.include?(target.id)
        redirect_to matching_path,
          alert: "거절된 상대에게는 같은 기수에 다시 요청할 수 없습니다." and return
      end
      retry_cost = Rails.application.config.x.blackticket.connect_retry_cost
      if Current.user.connect_retries_used_this_week(gen_week) >= 1
        redirect_to matching_path,
          alert: "이번 기수의 재요청 기회를 모두 사용했습니다." and return
      end
      if Current.user.ticket_credits < retry_cost
        redirect_to matching_path,
          alert: "재요청에 필요한 크레딧이 부족합니다 (#{retry_cost} 필요)." and return
      end

      ConnectRequest.transaction do
        Current.user.credit_transactions.create!(
          amount: -retry_cost, kind: :spend, memo: "connect_retry"
        )
        ConnectRequest.create!(requester: Current.user, target: target)
      end
      redirect_to matching_path,
        notice: "재요청을 보냈습니다 (-#{retry_cost} 크레딧)." and return
    end

    req = ConnectRequest.new(requester: Current.user, target: target)
    if req.save
      redirect_to matching_path, notice: "커넥트 요청을 보냈습니다."
    else
      redirect_to matching_path, alert: req.errors.full_messages.first
    end
  rescue ActiveRecord::RecordInvalid => e
    redirect_to matching_path, alert: e.record.errors.full_messages.first
  end

  def accept
    if Current.user.had_red_connect_this_week?(ConnectRequest.current_gen_week)
      redirect_to matching_path,
        alert: "이번 기수에 이미 성사된 커넥트가 있어 다른 요청을 수락할 수 없습니다." and return
    end
    req = Current.user.recv_connect_requests.find(params[:id])
    req.accept!
    redirect_to matching_path, notice: "커넥트가 성사되었습니다."
  end

  def reject
    req = Current.user.recv_connect_requests.find(params[:id])
    req.reject!
    redirect_to matching_path, notice: "요청을 거절했습니다."
  end

  def destroy
    req = Current.user.sent_connect_requests.find(params[:id])
    req.cancel! if req.pending?
    redirect_to matching_path, notice: "요청을 취소했습니다."
  end

  private
    def ensure_matching_active
      return if Current.user.matching_active?
      redirect_to matching_path, alert: "매칭이 활성화되지 않았습니다."
    end
end
