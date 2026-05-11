class MessagesController < ApplicationController
  before_action :set_conversation, only: %i[ create ]
  before_action :set_message, only: %i[ destroy ]
  before_action :require_participant, only: %i[ create ]

  rate_limit to: 30, within: 1.minute, only: :create,
    with: -> { redirect_to conversation_path(@conversation), alert: "쪽지 발송 한도를 초과했습니다. 잠시 후 다시 시도해주세요." }

  def create
    other = @conversation.other_for(Current.user)

    if Block.exists_between?(Current.user, other)
      redirect_to conversation_path(@conversation), alert: "차단된 사용자와는 메시지를 주고받을 수 없습니다." and return
    end

    @message = @conversation.messages.build(message_params)
    @message.sender = Current.user

    if @message.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to conversation_path(@conversation) }
      end
    else
      redirect_to conversation_path(@conversation), alert: @message.errors.full_messages.first
    end
  end

  def destroy
    unless @message.recallable_by?(Current.user)
      redirect_to conversation_path(@message.conversation), alert: "메시지 회수는 발송 5분 이내에만 가능합니다." and return
    end

    @message.destroy
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to conversation_path(@message.conversation), status: :see_other }
    end
  end

  private
    def set_conversation
      @conversation = Conversation.find(params[:conversation_id])
    end

    def set_message
      @message = Message.includes(:conversation).find(params[:id])
    end

    def require_participant
      return if @conversation.participant?(Current.user)
      redirect_to conversations_path, alert: "권한이 없습니다."
    end

    def message_params
      params.expect(message: [ :body, images: [] ])
    end
end
