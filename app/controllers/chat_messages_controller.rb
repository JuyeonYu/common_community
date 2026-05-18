class ChatMessagesController < ApplicationController
  before_action :set_red_connect

  def create
    msg = @red_connect.chat_messages.build(sender: Current.user, body: params.dig(:chat_message, :body))
    if msg.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to red_connect_path(@red_connect) }
      end
    else
      redirect_to red_connect_path(@red_connect), alert: msg.errors.full_messages.first
    end
  end

  # 발신자가 본인 메시지의 읽음 여부 노출 권한 구매 — 5 크레딧.
  def mark_read
    msg = @red_connect.chat_messages.find(params[:id])
    unless msg.sender_id == Current.user.id
      redirect_to red_connect_path(@red_connect),
        alert: "본인이 보낸 메시지만 결제할 수 있습니다." and return
    end
    if msg.read_check_paid?
      redirect_to red_connect_path(@red_connect),
        notice: "이미 결제된 메시지입니다." and return
    end
    cost = Rails.application.config.x.blackticket.chat_read_receipt_cost
    if Current.user.ticket_credits < cost
      redirect_to red_connect_path(@red_connect),
        alert: "읽음 확인에 필요한 크레딧이 부족합니다 (#{cost} 필요)." and return
    end

    ChatMessage.transaction do
      Current.user.credit_transactions.create!(
        amount: -cost, kind: :spend, related: msg, memo: "chat_read_receipt"
      )
      msg.update!(read_check_paid: true)
    end
    redirect_to red_connect_path(@red_connect),
      notice: "읽음 여부를 확인합니다 (-#{cost} 크레딧)."
  end

  private
    def set_red_connect
      @red_connect = RedConnect.for_user(Current.user).find(params[:red_connect_id])
    end
end
