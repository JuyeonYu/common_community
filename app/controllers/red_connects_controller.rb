class RedConnectsController < ApplicationController
  before_action :set_red_connect, only: %i[ show destroy ]

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

  private
    def set_red_connect
      @red_connect = RedConnect.for_user(Current.user).find(params[:id])
    end
end
