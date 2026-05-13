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

  private
    def set_red_connect
      @red_connect = RedConnect.for_user(Current.user).find(params[:red_connect_id])
    end
end
