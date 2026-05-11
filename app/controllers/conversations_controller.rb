class ConversationsController < ApplicationController
  before_action :set_conversation, only: %i[ show read ]
  before_action :require_participant, only: %i[ show read ]

  def index
    @pagy, @conversations = pagy(
      Current.user.conversations.includes(:user_one, :user_two).recent,
      limit: 30
    )
  end

  def show
    @conversation.mark_read_for(Current.user)
    @messages = @conversation.messages.status_visible.includes(:sender).oldest
    @other = @conversation.other_for(Current.user)
    @new_message = @conversation.messages.build
  end

  def create
    other = User.find(params[:with_user_id])

    if other.id == Current.user.id
      redirect_to conversations_path, alert: "자기 자신과 대화할 수 없습니다." and return
    end

    if Block.exists_between?(Current.user, other)
      redirect_to profile_path(other), alert: "차단된 사용자와 대화할 수 없습니다." and return
    end

    @conversation = Conversation.find_or_create_for(Current.user, other)
    redirect_to @conversation
  end

  # PATCH /conversations/:id/read — 클라이언트에서 새 메시지 도착 시 호출.
  # 응답은 head :no_content. 헤더 뱃지는 broadcast로 갱신됨.
  def read
    @conversation.mark_read_for(Current.user)
    Current.user.broadcast_messages_badge
    head :no_content
  end

  private
    def set_conversation
      @conversation = Conversation.find(params[:id])
    end

    def require_participant
      return if @conversation.participant?(Current.user)

      respond_to do |format|
        format.json { head :forbidden }
        format.html { redirect_to conversations_path, alert: "권한이 없습니다." }
      end
    end
end
