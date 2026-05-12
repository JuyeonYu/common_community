class ConnectRequestsController < ApplicationController
  before_action :ensure_matching_active

  def create
    target = User.find(params[:target_id])
    req = ConnectRequest.new(requester: Current.user, target: target)
    if req.save
      redirect_to matching_path, notice: "커넥트 요청을 보냈습니다."
    else
      redirect_to matching_path, alert: req.errors.full_messages.first
    end
  end

  def accept
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
