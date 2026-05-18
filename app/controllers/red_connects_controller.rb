class RedConnectsController < ApplicationController
  before_action :set_red_connect, only: %i[ show destroy extend_duration ]

  # 활성 커넥트 목록 (헤더 "메시지" 진입점).
  def index
    @active_red_connects = RedConnect.for_user(Current.user)
                                     .where(status: :active)
                                     .order(updated_at: :desc)
                                     .includes(:user_a, :user_b)
  end

  def show
    @other_user    = @red_connect.other_user(Current.user)
    @chat_messages = @red_connect.chat_messages.recent.includes(:sender)
    @chat_message  = ChatMessage.new
  end

  def destroy
    @red_connect.release!(reason: "manual", by: Current.user) if @red_connect.active?
    redirect_to red_connects_path, notice: "커넥트를 종료했습니다."
  end

  # 연장권 — 60 크레딧 차감, +1개월. released는 거절.
  def extend_duration
    unless @red_connect.extendable?
      redirect_to red_connect_path(@red_connect),
        alert: "해제된 커넥트는 연장할 수 없습니다." and return
    end
    cost = Rails.application.config.x.blackticket.red_connect_extension_cost
    if Current.user.ticket_credits < cost
      redirect_to red_connect_path(@red_connect),
        alert: "연장에 필요한 크레딧이 부족합니다 (#{cost} 필요)." and return
    end

    RedConnect.transaction do
      Current.user.credit_transactions.create!(
        amount: -cost, kind: :spend, related: @red_connect, memo: "red_connect_extension"
      )
      @red_connect.extend_duration!(by: Current.user)
    end
    redirect_to red_connect_path(@red_connect),
      notice: "커넥트를 1개월 연장했습니다 (-#{cost} 크레딧)."
  end

  private
    def set_red_connect
      @red_connect = RedConnect.for_user(Current.user).find(params[:id])
    end
end
